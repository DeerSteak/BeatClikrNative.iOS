//
//  ScheduledPolyrhythmEngine.swift
//  beatclikr
//
//  Created by Ben Funk on 5/11/26.
//

import AVFoundation
import Foundation

/// Sample-accurate polyrhythm engine using rolling, pre-rendered cycle blocks.
///
/// Beat and rhythm share one absolute sample origin and are mixed into the same
/// block so cycle reunions occur at an identical sample.
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

    private var beatBuffers: AudioBufferClipCache?
    private var rhythmBuffers: AudioBufferClipCache?
    private var isGraphConfigured = false

    private let scheduleAheadCount = 4
    private var beatCount = 1 // against

    private var rhythmCount = 1 // beats
    private var rollingBufferSlots: [AudioBufferSlot] = []
    private var nextRollingBlockIndex: Int64 = 0
    private var rollingOriginHostTime: UInt64 = 0

    // Incremented on every start/stop so stale callbacks self-discard
    private var sessionID = 0
    private var isPlaying = false
    private var currentBPM: Double = 60

    private weak var delegate: PolyrhythmAudioEngineDelegate?

    /// Cached mach timebase for host-tick ↔ nanosecond conversion
    private let timebaseInfo: mach_timebase_info_data_t = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()

    // MARK: - PolyrhythmAudioEngine

    func loadSounds(beatName: String, rhythmName: String, from sounds: [SoundFile]) throws {
        beatBuffers = nil
        rhythmBuffers = nil
        guard let beatSound = sounds.first(where: { $0.displayName == beatName }) else {
            throw PlaybackError.soundNotFound(beatName)
        }
        guard let rhythmSound = sounds.first(where: { $0.displayName == rhythmName }) else {
            throw PlaybackError.soundNotFound(rhythmName)
        }
        guard let beatFile = beatSound.audioFile else {
            throw PlaybackError.soundUnreadable(beatName)
        }
        guard let rhythmFile = rhythmSound.audioFile else {
            throw PlaybackError.soundUnreadable(rhythmName)
        }
        beatBuffers = try AudioBufferClipCache(source: readBuffer(from: beatFile, name: beatName))
        rhythmBuffers = try AudioBufferClipCache(source: readBuffer(from: rhythmFile, name: rhythmName))
    }

    func startPolyrhythm(bpm: Double, beats: Int, against: Int, delegate: PolyrhythmAudioEngineDelegate) throws {
        guard bpm > 0, beats >= 1, against >= 1 else {
            throw PlaybackError.invalidConfiguration
        }
        guard beatBuffers != nil, rhythmBuffers != nil else {
            throw PlaybackError.soundUnreadable("Polyrhythm")
        }
        guard engine.isRunning else {
            throw PlaybackError.engineStartFailed
        }
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        guard beatBuffers?.source.format == outputFormat,
              rhythmBuffers?.source.format == outputFormat
        else {
            throw PlaybackError.engineStartFailed
        }

        sessionID += 1
        beatNode.stop()
        rhythmNode.stop()
        beatNode.play()
        rhythmNode.play()

        self.delegate = delegate
        currentBPM = bpm
        beatCount = against
        rhythmCount = beats
        isPlaying = true

        let originHostTime = mach_absolute_time() + secondsToHostTicks(MetronomeConstants.firstBeatDelay)
        rollingOriginHostTime = originHostTime
        nextRollingBlockIndex = 0
        prepareRollingBuffers()
    }

    func stopPolyrhythm() {
        sessionID += 1
        isPlaying = false
        beatNode.stop()
        rhythmNode.stop()
        rollingBufferSlots = []
        nextRollingBlockIndex = 0
    }

    func start() throws {
        if !isGraphConfigured {
            engine.attach(beatNode)
            engine.attach(rhythmNode)
            engine.connect(beatNode, to: engine.mainMixerNode, format: nil)
            engine.connect(rhythmNode, to: engine.mainMixerNode, format: nil)
            isGraphConfigured = true
        }
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

    private func prepareRollingBuffers() {
        guard isPlaying, let beatBuffers, let rhythmBuffers else { return }
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        prewarmClips(
            cache: beatBuffers,
            idealFrameLength: format.sampleRate * 60 / currentBPM,
        )
        prewarmClips(
            cache: rhythmBuffers,
            idealFrameLength: format.sampleRate * Double(beatCount) * 60
                / (currentBPM * Double(rhythmCount)),
        )
        let idealFrames = format.sampleRate * Double(beatCount) * 60 / currentBPM
        let capacity = AVAudioFrameCount(ceil(idealFrames) + 1)
        let poolSize = idealFrames / format.sampleRate > 1 ? 2 : scheduleAheadCount
        rollingBufferSlots = (0 ..< poolSize).compactMap {
            _ in AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity).map { AudioBufferSlot(buffer: $0) }
        }
        guard rollingBufferSlots.count == poolSize else {
            isPlaying = false
            return
        }

        let muted = UserDefaultsService.instance.muteMetronome
        beatNode.volume = muted ? 0 : 1
        rhythmNode.volume = 0
        for slot in rollingBufferSlots {
            scheduleRollingBlock(using: slot)
        }
    }

    private func prewarmClips(cache: AudioBufferClipCache, idealFrameLength: Double) {
        let lengths = Set([
            AVAudioFrameCount(floor(idealFrameLength)),
            AVAudioFrameCount(ceil(idealFrameLength)),
        ])
        for length in lengths where length > 0 {
            _ = cache.buffer(maximumFrameLength: length)
        }
    }

    private func scheduleRollingBlock(using slot: AudioBufferSlot) {
        guard isPlaying, let beatBuffers, let rhythmBuffers else {
            return
        }
        let capturedSession = sessionID
        let blockIndex = nextRollingBlockIndex
        guard let plan = try? PolyrhythmAudioBlockPlan(
            blockIndex: blockIndex,
            sampleRate: slot.buffer.format.sampleRate,
            bpm: currentBPM,
            beats: rhythmCount,
            against: beatCount,
        ) else {
            return
        }
        guard plan.frameCount <= slot.buffer.frameCapacity else {
            return
        }

        AudioBlockRenderer.clear(slot.buffer, frameCount: plan.frameCount)
        for event in plan.beatEvents {
            let source = beatBuffers.buffer(maximumFrameLength: event.maximumFrameLength)
            AudioBlockRenderer.mix(source, at: event.relativeSample, into: slot.buffer)
            scheduleDelegateEvent(
                beatFired: true,
                rhythmFired: false,
                beatIndex: event.index,
                rhythmIndex: 0,
                hostTime: rollingHostTime(forAbsoluteSample: event.absoluteSample, sampleRate: slot.buffer.format.sampleRate),
                sessionID: capturedSession,
            )
        }
        for event in plan.rhythmEvents {
            let source = rhythmBuffers.buffer(maximumFrameLength: event.maximumFrameLength)
            AudioBlockRenderer.mix(source, at: event.relativeSample, into: slot.buffer)
            scheduleDelegateEvent(
                beatFired: false,
                rhythmFired: true,
                beatIndex: 0,
                rhythmIndex: event.index,
                hostTime: rollingHostTime(forAbsoluteSample: event.absoluteSample, sampleRate: slot.buffer.format.sampleRate),
                sessionID: capturedSession,
            )
        }

        let blockHostTime = rollingHostTime(
            forAbsoluteSample: plan.absoluteStartSample,
            sampleRate: slot.buffer.format.sampleRate,
        )
        beatNode.scheduleBuffer(
            slot.buffer,
            at: AVAudioTime(hostTime: blockHostTime),
            options: [],
            completionCallbackType: .dataConsumed,
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.sessionID == capturedSession else { return }
                self.scheduleRollingBlock(using: slot)
            }
        }
        nextRollingBlockIndex += 1
    }

    private func rollingHostTime(forAbsoluteSample sample: Int64, sampleRate: Double) -> UInt64 {
        rollingOriginHostTime + secondsToHostTicks(Double(sample) / sampleRate)
    }

    private func readBuffer(from file: AVAudioFile, name: String) throws -> AVAudioPCMBuffer {
        file.framePosition = 0
        guard let sourceBuffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length),
        ) else { throw PlaybackError.soundUnreadable(name) }
        do {
            try file.read(into: sourceBuffer)
        } catch {
            throw PlaybackError.soundUnreadable(name)
        }

        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        guard sourceBuffer.format != outputFormat else { return sourceBuffer }
        guard let converter = AVAudioConverter(from: sourceBuffer.format, to: outputFormat) else { return sourceBuffer }

        let convertedFrameCapacity = AVAudioFrameCount(
            ceil(Double(sourceBuffer.frameLength) * outputFormat.sampleRate / sourceBuffer.format.sampleRate),
        )
        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: max(convertedFrameCapacity, 1),
        ) else { throw PlaybackError.soundConversionFailed(name) }

        let inputProvider = PolyrhythmConversionInputProvider(buffer: sourceBuffer)
        var conversionError: NSError?
        converter.convert(to: convertedBuffer, error: &conversionError) { _, outStatus in
            inputProvider.nextBuffer(outStatus: outStatus)
        }

        if conversionError != nil {
            throw PlaybackError.soundConversionFailed(name)
        }
        return convertedBuffer
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
