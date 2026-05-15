//
//  ScheduledPolyrhythmEngine.swift
//  beatclikr
//
//  Created by Ben Funk on 5/11/26.
//

import AVFoundation
import Foundation

/// Sample-accurate polyrhythm engine using two independent AVAudioPlayerNode tracks.
///
/// Beat and rhythm run as completely separate scheduling loops so they can fire at the
/// same sample time without any buffer-mixing code; AVAudioEngine handles the mix.
/// Delegate notifications are scheduled from the same host-time timeline as playback
/// instead of using buffer completion as a proxy for beat onset.
///
/// Both audio (AVAudioTime hostTime) and UI (DispatchTime uptimeNanoseconds) are
/// anchored to mach_absolute_time, eliminating clock-domain drift between them.
///
/// For M against N:
///   - Beat track fires every quarter note (60/bpm seconds)
///   - Rhythm track fires every cycle/M seconds  (N*60 / (bpm*M) seconds)
///   - Both tracks start at the same firstBeatDelay origin
@MainActor
class ScheduledPolyrhythmEngine: PolyrhythmAudioEngine {
    private let engine = AVAudioEngine()
    private let beatNode = AVAudioPlayerNode()
    private let rhythmNode = AVAudioPlayerNode()

    private var beatBuffer: AVAudioPCMBuffer?
    private var rhythmBuffer: AVAudioPCMBuffer?

    // Beat track state
    private let scheduleAheadCount = 4
    private var beatScheduledCount = 0
    private var beatNextHostTime: UInt64 = 0
    private var beatHostTicksDelta: UInt64 = 0
    private var beatFramesPerInterval: AVAudioFrameCount = 0
    private var currentBeatIndex = 0
    private var beatCount = 1 // against

    // Rhythm track state
    private var rhythmScheduledCount = 0
    private var rhythmNextHostTime: UInt64 = 0
    private var rhythmHostTicksDelta: UInt64 = 0
    private var rhythmFramesPerInterval: AVAudioFrameCount = 0
    private var currentRhythmIndex = 0
    private var rhythmCount = 1 // beats

    // Incremented on every start/stop so stale callbacks self-discard
    private var sessionID = 0
    private var isPlaying = false

    private weak var delegate: PolyrhythmAudioEngineDelegate?

    /// Cached mach timebase for host-tick ↔ nanosecond conversion
    private let timebaseInfo: mach_timebase_info_data_t = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()

    // MARK: - PolyrhythmAudioEngine

    func loadSounds(beatName: String, rhythmName: String, from sounds: [SoundFile]) {
        if let file = sounds.first(where: { $0.displayName == beatName })?.audioFile {
            beatBuffer = readBuffer(from: file)
        }
        if let file = sounds.first(where: { $0.displayName == rhythmName })?.audioFile {
            rhythmBuffer = readBuffer(from: file)
        }
    }

    func startPolyrhythm(bpm: Double, beats: Int, against: Int, delegate: PolyrhythmAudioEngineDelegate) {
        guard bpm > 0, beats >= 1, against >= 1 else { return }

        sessionID += 1
        beatNode.stop()
        rhythmNode.stop()
        beatNode.play()
        rhythmNode.play()

        self.delegate = delegate
        beatCount = against
        rhythmCount = beats
        isPlaying = true

        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        let samplesPerBeat = sampleRate * 60.0 / bpm
        let samplesPerRhythm = sampleRate * Double(against) * 60.0 / (bpm * Double(beats))

        beatFramesPerInterval = AVAudioFrameCount(samplesPerBeat)
        rhythmFramesPerInterval = AVAudioFrameCount(samplesPerRhythm)
        beatHostTicksDelta = secondsToHostTicks(Double(beatFramesPerInterval) / sampleRate)
        rhythmHostTicksDelta = secondsToHostTicks(Double(rhythmFramesPerInterval) / sampleRate)

        let originHostTime = mach_absolute_time() + secondsToHostTicks(MetronomeConstants.firstBeatDelay)
        beatNextHostTime = originHostTime
        rhythmNextHostTime = originHostTime
        currentBeatIndex = 0
        currentRhythmIndex = 0
        beatScheduledCount = 0
        rhythmScheduledCount = 0

        scheduleBeatBuffers()
        scheduleRhythmBuffers()
    }

    func stopPolyrhythm() {
        sessionID += 1
        isPlaying = false
        beatNode.stop()
        rhythmNode.stop()
        beatScheduledCount = 0
        rhythmScheduledCount = 0
    }

    func start() throws {
        engine.attach(beatNode)
        engine.attach(rhythmNode)
        engine.connect(beatNode, to: engine.mainMixerNode, format: nil)
        engine.connect(rhythmNode, to: engine.mainMixerNode, format: nil)
        try engine.start()
    }

    func stop() {
        beatNode.stop()
        rhythmNode.stop()
        engine.stop()
    }

    // MARK: - Private

    private func secondsToHostTicks(_ seconds: Double) -> UInt64 {
        let nanoseconds = seconds * 1_000_000_000
        return UInt64(nanoseconds) * UInt64(timebaseInfo.denom) / UInt64(timebaseInfo.numer)
    }

    private func hostTicksToNanoseconds(_ ticks: UInt64) -> UInt64 {
        ticks * UInt64(timebaseInfo.numer) / UInt64(timebaseInfo.denom)
    }

    private func readBuffer(from file: AVAudioFile) -> AVAudioPCMBuffer? {
        file.framePosition = 0
        guard let sourceBuffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length),
        ) else { return nil }
        try? file.read(into: sourceBuffer)

        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        guard sourceBuffer.format != outputFormat else { return sourceBuffer }
        guard let converter = AVAudioConverter(from: sourceBuffer.format, to: outputFormat) else { return sourceBuffer }

        let convertedFrameCapacity = AVAudioFrameCount(
            ceil(Double(sourceBuffer.frameLength) * outputFormat.sampleRate / sourceBuffer.format.sampleRate),
        )
        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: max(convertedFrameCapacity, 1),
        ) else { return sourceBuffer }

        let inputProvider = PolyrhythmConversionInputProvider(buffer: sourceBuffer)
        var conversionError: NSError?
        converter.convert(to: convertedBuffer, error: &conversionError) { _, outStatus in
            inputProvider.nextBuffer(outStatus: outStatus)
        }

        if let conversionError {
            print("Could not convert polyrhythm buffer: \(conversionError)")
            return sourceBuffer
        }
        return convertedBuffer
    }

    private func scheduleBeatBuffers() {
        guard isPlaying, let buffer = beatBuffer else { return }

        let capturedSession = sessionID
        let muted = UserDefaultsService.instance.muteMetronome
        beatNode.volume = muted ? 0 : 1

        while beatScheduledCount < scheduleAheadCount {
            let capturedIndex = currentBeatIndex
            let scheduledHostTime = beatNextHostTime
            let when = AVAudioTime(hostTime: scheduledHostTime)

            scheduleDelegateEvent(
                beatFired: true,
                rhythmFired: false,
                beatIndex: capturedIndex,
                rhythmIndex: 0,
                hostTime: scheduledHostTime,
                sessionID: capturedSession,
            )

            buffer.frameLength = min(buffer.frameCapacity, beatFramesPerInterval)
            beatNode.scheduleBuffer(buffer, at: when, options: [], completionCallbackType: .dataConsumed) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self, self.sessionID == capturedSession else { return }
                    self.beatScheduledCount -= 1
                    self.scheduleBeatBuffers()
                }
            }

            beatNextHostTime += beatHostTicksDelta
            currentBeatIndex = (currentBeatIndex + 1) % beatCount
            beatScheduledCount += 1
        }
    }

    private func scheduleRhythmBuffers() {
        guard isPlaying, let buffer = rhythmBuffer else { return }

        let capturedSession = sessionID
        let muted = UserDefaultsService.instance.muteMetronome
        rhythmNode.volume = muted ? 0 : 1

        while rhythmScheduledCount < scheduleAheadCount {
            let capturedIndex = currentRhythmIndex
            let scheduledHostTime = rhythmNextHostTime
            let when = AVAudioTime(hostTime: scheduledHostTime)

            scheduleDelegateEvent(
                beatFired: false,
                rhythmFired: true,
                beatIndex: 0,
                rhythmIndex: capturedIndex,
                hostTime: scheduledHostTime,
                sessionID: capturedSession,
            )

            buffer.frameLength = min(buffer.frameCapacity, rhythmFramesPerInterval)
            rhythmNode.scheduleBuffer(buffer, at: when, options: [], completionCallbackType: .dataConsumed) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self, self.sessionID == capturedSession else { return }
                    self.rhythmScheduledCount -= 1
                    self.scheduleRhythmBuffers()
                }
            }

            rhythmNextHostTime += rhythmHostTicksDelta
            currentRhythmIndex = (currentRhythmIndex + 1) % rhythmCount
            rhythmScheduledCount += 1
        }
    }

    private func scheduleDelegateEvent(
        beatFired: Bool,
        rhythmFired: Bool,
        beatIndex: Int,
        rhythmIndex: Int,
        hostTime: UInt64,
        sessionID capturedSession: Int,
    ) {
        let deadlineNs = hostTicksToNanoseconds(hostTime)
        let deadline = DispatchTime(uptimeNanoseconds: deadlineNs)
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            guard let self, sessionID == capturedSession else { return }
            delegate?.polyrhythmBeatFired(
                beatFired: beatFired,
                rhythmFired: rhythmFired,
                beatIndex: beatIndex,
                rhythmIndex: rhythmIndex,
            )
        }
    }
}

private final class PolyrhythmConversionInputProvider: @unchecked Sendable {
    private let buffer: AVAudioPCMBuffer
    private let lock = NSLock()
    private var didProvideInput = false

    init(buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
    }

    func nextBuffer(outStatus: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? {
        lock.lock()
        defer { lock.unlock() }

        guard !didProvideInput else {
            outStatus.pointee = .noDataNow
            return nil
        }

        didProvideInput = true
        outStatus.pointee = .haveData
        return buffer
    }
}
