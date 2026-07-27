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

    private var beatBuffers: AudioBufferClipCache?
    private var rhythmBuffers: AudioBufferClipCache?
    private var isGraphConfigured = false

    private var scheduledCount = 0
    private var nextBeatHostTime: UInt64 = 0
    private let scheduleAheadCount = 4
    private var rollingBufferSlots: [AudioBufferSlot] = []
    private var nextRollingBlockIndex: Int64 = 0
    private var rollingOriginHostTime: UInt64 = 0

    private enum PlaybackPath {
        case dynamic
        case rolling
    }

    private var playbackPath: PlaybackPath = .rolling

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

    func startMetronome(bpm: Double, subdivisions: Int, accentPattern: [Bool]?, delegate: MetronomeAudioEngineDelegate) throws {
        guard bpm > 0, subdivisions > 0 else {
            throw PlaybackError.invalidConfiguration
        }
        guard beatBuffers != nil, rhythmBuffers != nil else {
            throw PlaybackError.soundUnreadable("Metronome")
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
        restartPlaybackTimeline()
    }

    func stopMetronome() {
        sessionID += 1
        isPlaying = false
        beatNode.stop()
        rhythmNode.stop()
        scheduledCount = 0
        rollingBufferSlots = []
        nextRollingBlockIndex = 0
        currentSubdivision = 0
        patternIndex = 0
        rampBeatCount = -1
    }

    func updateTempo(bpm: Double, subdivisions: Int) {
        currentBPM = bpm
        currentSubdivisions = subdivisions
        useAlternateSixteenth = UserDefaultsService.instance.sixteenthAlternate && subdivisions == 4
        if isPlaying, playbackPath == .rolling {
            restartPlaybackTimeline()
        }
    }

    func setRamp(enabled: Bool, increment: Int, interval: Int) {
        let pathChanged = rampEnabled != enabled
        rampEnabled = enabled
        rampIncrement = Double(increment)
        rampInterval = max(1, interval)
        if isPlaying, pathChanged {
            restartPlaybackTimeline()
        }
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

    private func restartPlaybackTimeline() {
        sessionID += 1
        beatNode.stop()
        rhythmNode.stop()
        scheduledCount = 0
        currentSubdivision = 0
        patternIndex = 0
        rampBeatCount = -1

        let origin = mach_absolute_time() + secondsToHostTicks(MetronomeConstants.firstBeatDelay)
        if rampEnabled {
            playbackPath = .dynamic
            rollingBufferSlots = []
            nextBeatHostTime = origin
            beatNode.play()
            rhythmNode.play()
            scheduleNextBeats()
        } else {
            playbackPath = .rolling
            rollingOriginHostTime = origin
            nextRollingBlockIndex = 0
            prepareRollingBuffers()
            guard isPlaying else { return }
            beatNode.play(at: AVAudioTime(hostTime: origin))
            rhythmNode.play(at: AVAudioTime(hostTime: origin))
        }
    }

    private func prepareRollingBuffers() {
        guard isPlaying, let beatBuffers, let rhythmBuffers else { return }
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let intervalCount = accentPattern?.count ?? currentSubdivisions
        let idealIntervalFrames = format.sampleRate * 60 / (currentBPM * Double(currentSubdivisions))
        prewarmClips(
            caches: [beatBuffers, rhythmBuffers],
            idealFrameLength: idealIntervalFrames,
        )
        let idealFrames = Double(intervalCount) * format.sampleRate * 60
            / (currentBPM * Double(currentSubdivisions))
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

    private func prewarmClips(caches: [AudioBufferClipCache], idealFrameLength: Double) {
        let lengths = Set([
            AVAudioFrameCount(floor(idealFrameLength)),
            AVAudioFrameCount(ceil(idealFrameLength)),
        ])
        for cache in caches {
            for length in lengths where length > 0 {
                _ = cache.buffer(maximumFrameLength: length)
            }
        }
    }

    private func scheduleRollingBlock(using slot: AudioBufferSlot) {
        guard isPlaying,
              playbackPath == .rolling,
              let beatBuffers,
              let rhythmBuffers
        else {
            return
        }

        let capturedSession = sessionID
        let blockIndex = nextRollingBlockIndex
        guard let plan = try? MetronomeAudioBlockPlan(
            blockIndex: blockIndex,
            sampleRate: slot.buffer.format.sampleRate,
            bpm: currentBPM,
            subdivisions: currentSubdivisions,
            accentPattern: accentPattern,
            alternateSixteenth: useAlternateSixteenth,
        ) else {
            return
        }
        guard plan.frameCount <= slot.buffer.frameCapacity else {
            return
        }

        AudioBlockRenderer.clear(slot.buffer, frameCount: plan.frameCount)
        for event in plan.events {
            let source = (event.usesBeatSound ? beatBuffers : rhythmBuffers)
                .buffer(maximumFrameLength: event.maximumFrameLength)
            AudioBlockRenderer.mix(source, at: event.relativeSample, into: slot.buffer)
            scheduleDelegateEvent(
                isBeat: event.isBeat,
                beatInterval: event.beatInterval,
                rampedBpm: nil,
                hostTime: rollingHostTime(forAbsoluteSample: event.absoluteSample, sampleRate: slot.buffer.format.sampleRate),
                targetSample: event.absoluteSample,
                sampleRate: slot.buffer.format.sampleRate,
                sessionID: capturedSession,
            )
        }

        // The player itself is host-time anchored after the initial queue is built.
        // Every buffer is appended so boundaries remain on its integer sample timeline.
        beatNode.scheduleBuffer(
            slot.buffer,
            at: nil,
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

        let inputProvider = MetronomeConversionInputProvider(buffer: sourceBuffer)
        var conversionError: NSError?
        converter.convert(to: convertedBuffer, error: &conversionError) { _, outStatus in
            inputProvider.nextBuffer(outStatus: outStatus)
        }

        if conversionError != nil {
            throw PlaybackError.soundConversionFailed(name)
        }
        return convertedBuffer
    }

    private struct ScheduledBeat {
        let buffer: AVAudioPCMBuffer
        let isBeat: Bool
        let beatInterval: TimeInterval
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
            guard let buffers = isBeat ? beatBuffers : rhythmBuffers else { return nil }

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
            let audio = buffers.buffer(maximumFrameLength: framesPerInterval)
            return ScheduledBeat(buffer: audio, isBeat: isBeat, beatInterval: beatInterval, hostTicksDelta: hostTicksDelta, rampedBpm: rampedBpm)
        } else {
            let isBeat = currentSubdivision == 0
            let playBeat = useAlternateSixteenth ? currentSubdivision % 2 == 0 : currentSubdivision == 0
            guard let buffers = playBeat ? beatBuffers : rhythmBuffers else { return nil }
            let beatInterval = 60.0 / currentBPM
            currentSubdivision = (currentSubdivision + 1) % currentSubdivisions
            let audio = buffers.buffer(maximumFrameLength: framesPerInterval)
            return ScheduledBeat(buffer: audio, isBeat: isBeat, beatInterval: beatInterval, hostTicksDelta: hostTicksDelta, rampedBpm: rampedBpm)
        }
    }

    private func scheduleNextBeats() {
        guard isPlaying, playbackPath == .dynamic else { return }

        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate

        let muted = UserDefaultsService.instance.muteMetronome
        beatNode.volume = muted ? 0 : 1
        rhythmNode.volume = muted ? 0 : 1

        let capturedSession = sessionID

        while scheduledCount < scheduleAheadCount {
            guard let beat = nextBeat(sampleRate: sampleRate) else { break }

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
        targetSample: Int64? = nil,
        sampleRate: Double? = nil,
        presentationLatencyIncluded: Bool = false,
        sessionID capturedSession: Int,
    ) {
        let presentationLatency = targetSample == nil ? 0 : beatNode.outputPresentationLatency
        let deadlineHostTime = hostTime
            + (presentationLatencyIncluded ? 0 : secondsToHostTicks(presentationLatency))
        let deadlineNs = hostTicksToNanoseconds(deadlineHostTime)
        let deadline = DispatchTime(uptimeNanoseconds: deadlineNs)
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            guard let self, sessionID == capturedSession else { return }
            if let targetSample, let sampleRate {
                let presentationFrames = Int64((beatNode.outputPresentationLatency * sampleRate).rounded())
                let presentedTarget = targetSample + presentationFrames
                guard renderedSamplePosition() >= presentedTarget else {
                    scheduleDelegateEvent(
                        isBeat: isBeat,
                        beatInterval: beatInterval,
                        rampedBpm: rampedBpm,
                        hostTime: mach_absolute_time() + secondsToHostTicks(1.0 / 120.0),
                        targetSample: targetSample,
                        sampleRate: sampleRate,
                        presentationLatencyIncluded: true,
                        sessionID: capturedSession,
                    )
                    return
                }
            }
            if let newBpm = rampedBpm {
                delegate?.metronomeRampStepped(newBpm: newBpm)
            }
            delegate?.metronomeBeatFired(isBeat: isBeat, beatInterval: beatInterval)
        }
    }

    private func renderedSamplePosition() -> Int64 {
        guard let renderTime = beatNode.lastRenderTime,
              let playerTime = beatNode.playerTime(forNodeTime: renderTime),
              playerTime.isSampleTimeValid
        else {
            return -1
        }
        return playerTime.sampleTime
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
