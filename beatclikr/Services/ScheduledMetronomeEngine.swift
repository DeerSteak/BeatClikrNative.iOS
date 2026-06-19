//
//  ScheduledMetronomeEngine.swift
//  beatclikr
//
//  Created by Ben Funk on 5/11/26.
//

import AVFoundation
import Foundation

/// Sample-accurate metronome engine using AVAudioPlayerNode scheduled buffers.
/// Pre-schedules audio buffers on the audio thread for sample-accurate playback.
/// UI, haptic, flashlight, and ramp notifications are scheduled separately from
/// the same sample timeline so buffer completion does not masquerade as beat onset.
///
/// Both audio (AVAudioTime hostTime) and UI (DispatchTime uptimeNanoseconds) are
/// anchored to mach_absolute_time, eliminating clock-domain drift between them.
@MainActor
class ScheduledMetronomeEngine: MetronomeAudioEngine {
    private let engine = AVAudioEngine()
    private let beatNode = AVAudioPlayerNode()
    private let rhythmNode = AVAudioPlayerNode()

    private var beatBuffer: AVAudioPCMBuffer?
    private var rhythmBuffer: AVAudioPCMBuffer?

    private var scheduledCount = 0
    private var nextBeatHostTime: UInt64 = 0
    private let scheduleAheadCount = 4

    // Incremented on every start/stop so callbacks from prior sessions self-discard
    private var sessionID = 0
    private var isPlaying = false
    private var currentBPM: Double = 60
    private var currentSubdivisions: Int = 1
    private var currentSubdivision: Int = 0
    private var useAlternateSixteenth = false
    private var accentPattern: [Bool]?
    private var patternIndex = 0

    // Ramp state - precomputed into the scheduling lookahead
    private var rampEnabled = false
    private var rampIncrement: Double = 0
    private var rampInterval: Int = 1
    private var rampBeatCount: Int = -1

    private weak var delegate: MetronomeAudioEngineDelegate?

    /// Cached mach timebase for host-tick ↔ nanosecond conversion
    private let timebaseInfo: mach_timebase_info_data_t = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()

    // MARK: - MetronomeAudioEngine

    func loadSounds(beatName: String, rhythmName: String, from sounds: [SoundFile]) {
        if let file = sounds.first(where: { $0.displayName == beatName })?.audioFile {
            beatBuffer = readBuffer(from: file)
        }
        if let file = sounds.first(where: { $0.displayName == rhythmName })?.audioFile {
            rhythmBuffer = readBuffer(from: file)
        }
    }

    func startMetronome(bpm: Double, subdivisions: Int, accentPattern: [Bool]?, delegate: MetronomeAudioEngineDelegate) {
        sessionID += 1
        beatNode.stop()
        rhythmNode.stop()
        beatNode.play()
        rhythmNode.play()

        currentBPM = bpm
        currentSubdivisions = subdivisions
        self.accentPattern = accentPattern
        self.delegate = delegate
        useAlternateSixteenth = UserDefaultsService.instance.sixteenthAlternate && subdivisions == 4
        currentSubdivision = 0
        patternIndex = 0
        scheduledCount = 0
        rampBeatCount = -1
        isPlaying = true

        // Anchor both audio and UI events to the same mach_absolute_time baseline.
        // AVAudioTime(hostTime:) and DispatchTime(uptimeNanoseconds:) both derive from
        // mach_absolute_time, so scheduling via host ticks eliminates clock-domain drift.
        nextBeatHostTime = mach_absolute_time() + secondsToHostTicks(MetronomeConstants.firstBeatDelay)

        scheduleNextBeats()
    }

    func stopMetronome() {
        sessionID += 1
        isPlaying = false
        beatNode.stop()
        rhythmNode.stop()
        scheduledCount = 0
        currentSubdivision = 0
        patternIndex = 0
        rampBeatCount = -1
    }

    func updateTempo(bpm: Double, subdivisions: Int) {
        currentBPM = bpm
        currentSubdivisions = subdivisions
        useAlternateSixteenth = UserDefaultsService.instance.sixteenthAlternate && subdivisions == 4
        // Already-scheduled buffers drain naturally; new ones use the updated tempo
    }

    func setRamp(enabled: Bool, increment: Int, interval: Int) {
        rampEnabled = enabled
        rampIncrement = Double(increment)
        rampInterval = max(1, interval)
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

        let inputProvider = MetronomeConversionInputProvider(buffer: sourceBuffer)
        var conversionError: NSError?
        converter.convert(to: convertedBuffer, error: &conversionError) { _, outStatus in
            inputProvider.nextBuffer(outStatus: outStatus)
        }

        if let conversionError {
            print("Could not convert metronome buffer: \(conversionError)")
            return sourceBuffer
        }
        return convertedBuffer
    }

    private struct ScheduledBeat {
        let buffer: AVAudioPCMBuffer
        let isBeat: Bool
        let beatInterval: TimeInterval
        let framesPerInterval: AVAudioFrameCount
        let hostTicksDelta: UInt64
        let rampedBpm: Double?
    }

    private func nextBeat(sampleRate: Double) -> ScheduledBeat? {
        // Determine whether this slot is a downbeat before mutating any state
        let willBeBeat: Bool = if let pattern = accentPattern {
            pattern[patternIndex]
        } else {
            currentSubdivision == 0
        }

        // Apply ramp step before computing spacing so the new BPM is baked into
        // this beat's timing and all subsequent scheduled beats.
        var rampedBpm: Double? = nil
        if rampEnabled, willBeBeat {
            rampBeatCount += 1
            if rampBeatCount > 0, rampBeatCount % rampInterval == 0 {
                let newBpm = min(currentBPM + rampIncrement, MetronomeConstants.maxBPM)
                if newBpm != currentBPM {
                    currentBPM = newBpm
                    rampedBpm = newBpm
                }
            }
        }

        let subdivisionsPerSecond = (currentBPM / 60.0) * Double(currentSubdivisions)
        let subdivisionDuration = 1.0 / subdivisionsPerSecond
        let samplesPerSubdivision = sampleRate / subdivisionsPerSecond
        let framesPerInterval = AVAudioFrameCount(samplesPerSubdivision)
        // Advance host time by the exact buffer duration (integer frames) so audio
        // and host-time scheduling stay sample-aligned.
        let hostTicksDelta = secondsToHostTicks(Double(framesPerInterval) / sampleRate)

        if let pattern = accentPattern {
            let isBeat = pattern[patternIndex]
            guard let audio = isBeat ? beatBuffer : rhythmBuffer else { return nil }

            let beatInterval: TimeInterval
            if isBeat {
                var ticksToNext = 1
                var look = (patternIndex + 1) % pattern.count
                while !pattern[look], ticksToNext < pattern.count {
                    ticksToNext += 1
                    look = (look + 1) % pattern.count
                }
                beatInterval = subdivisionDuration * Double(ticksToNext)
            } else {
                beatInterval = subdivisionDuration
            }
            patternIndex = (patternIndex + 1) % pattern.count
            return ScheduledBeat(buffer: audio, isBeat: isBeat, beatInterval: beatInterval, framesPerInterval: framesPerInterval, hostTicksDelta: hostTicksDelta, rampedBpm: rampedBpm)
        } else {
            let isBeat = currentSubdivision == 0
            let playBeat = useAlternateSixteenth ? currentSubdivision % 2 == 0 : currentSubdivision == 0
            guard let audio = playBeat ? beatBuffer : rhythmBuffer else { return nil }
            let beatInterval = 60.0 / currentBPM
            currentSubdivision = (currentSubdivision + 1) % currentSubdivisions
            return ScheduledBeat(buffer: audio, isBeat: isBeat, beatInterval: beatInterval, framesPerInterval: framesPerInterval, hostTicksDelta: hostTicksDelta, rampedBpm: rampedBpm)
        }
    }

    private func scheduleNextBeats() {
        guard isPlaying else { return }

        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate

        let muted = UserDefaultsService.instance.muteMetronome
        beatNode.volume = muted ? 0 : 1
        rhythmNode.volume = muted ? 0 : 1

        let capturedSession = sessionID

        while scheduledCount < scheduleAheadCount {
            guard let beat = nextBeat(sampleRate: sampleRate) else { break }

            beat.buffer.frameLength = min(beat.buffer.frameCapacity, beat.framesPerInterval)

            let node = beat.isBeat ? beatNode : rhythmNode
            let scheduledHostTime = nextBeatHostTime
            let when = AVAudioTime(hostTime: scheduledHostTime)

            scheduleDelegateEvent(
                isBeat: beat.isBeat,
                beatInterval: beat.beatInterval,
                rampedBpm: beat.rampedBpm,
                hostTime: scheduledHostTime,
                sessionID: capturedSession,
            )

            node.scheduleBuffer(beat.buffer, at: when, options: [], completionCallbackType: .dataConsumed) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self, self.sessionID == capturedSession else { return }
                    self.scheduledCount -= 1
                    self.scheduleNextBeats()
                }
            }

            nextBeatHostTime += beat.hostTicksDelta
            scheduledCount += 1
        }
    }

    private func scheduleDelegateEvent(
        isBeat: Bool,
        beatInterval: TimeInterval,
        rampedBpm: Double?,
        hostTime: UInt64,
        sessionID capturedSession: Int,
    ) {
        // Both AVAudioTime.hostTime and DispatchTime derive from mach_absolute_time,
        // so this deadline fires at the exact same moment the audio buffer plays.
        let deadlineNs = hostTicksToNanoseconds(hostTime)
        let deadline = DispatchTime(uptimeNanoseconds: deadlineNs)
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            guard let self, sessionID == capturedSession else { return }
            if let newBpm = rampedBpm {
                delegate?.metronomeRampStepped(newBpm: newBpm)
            }
            delegate?.metronomeBeatFired(isBeat: isBeat, beatInterval: beatInterval)
        }
    }
}

private final class MetronomeConversionInputProvider: @unchecked Sendable {
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
