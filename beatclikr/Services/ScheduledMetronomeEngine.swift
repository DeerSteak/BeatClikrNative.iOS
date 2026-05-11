//
//  ScheduledMetronomeEngine.swift
//  beatclikr
//
//  Created by Ben Funk on 5/11/26.
//

import AVFoundation
import Foundation

/// Sample-accurate metronome engine using AVAudioPlayerNode scheduled buffers.
/// Eliminates timer polling by pre-scheduling audio buffers on the audio thread,
/// achieving hardware-level timing precision with no main-thread jitter.
@MainActor
class ScheduledMetronomeEngine: MetronomeAudioEngine {
    private let engine = AVAudioEngine()
    private let beatNode = AVAudioPlayerNode()
    private let rhythmNode = AVAudioPlayerNode()

    private var beatBuffer: AVAudioPCMBuffer?
    private var rhythmBuffer: AVAudioPCMBuffer?

    private var scheduledCount = 0
    private var nextBeatSampleTime: AVAudioFramePosition = 0
    private let scheduleAheadCount = 4

    // Incremented on every start/stop so completion callbacks from prior sessions self-discard
    private var sessionID = 0
    private var isPlaying = false
    private var currentBPM: Double = 60
    private var currentSubdivisions: Int = 1
    private var currentSubdivision: Int = 0
    private var useAlternateSixteenth = false
    private var accentPattern: [Bool]?
    private var patternIndex = 0

    // Ramp state — precomputed into the scheduling lookahead
    private var rampEnabled = false
    private var rampIncrement: Double = 0
    private var rampInterval: Int = 1
    private var rampBeatCount: Int = -1

    private weak var delegate: MetronomeAudioEngineDelegate?

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

        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        nextBeatSampleTime = AVAudioFramePosition(sampleRate * MetronomeConstants.firstBeatDelay)

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

    private func readBuffer(from file: AVAudioFile) -> AVAudioPCMBuffer? {
        file.framePosition = 0
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length),
        ) else { return nil }
        try? file.read(into: buffer)
        return buffer
    }

    private struct ScheduledBeat {
        let buffer: AVAudioPCMBuffer
        let isBeat: Bool
        let beatInterval: TimeInterval
        let samplesPerSubdivision: Double
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
        // this beat's samplesPerSubdivision and all subsequent scheduled beats.
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
            return ScheduledBeat(buffer: audio, isBeat: isBeat, beatInterval: beatInterval, samplesPerSubdivision: samplesPerSubdivision, rampedBpm: rampedBpm)
        } else {
            let isBeat = currentSubdivision == 0
            let playBeat = useAlternateSixteenth ? currentSubdivision % 2 == 0 : currentSubdivision == 0
            guard let audio = playBeat ? beatBuffer : rhythmBuffer else { return nil }
            let beatInterval = 60.0 / currentBPM
            currentSubdivision = (currentSubdivision + 1) % currentSubdivisions
            return ScheduledBeat(buffer: audio, isBeat: isBeat, beatInterval: beatInterval, samplesPerSubdivision: samplesPerSubdivision, rampedBpm: rampedBpm)
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

            // Cap buffer playback length to this beat's interval so the completion
            // callback fires at the beat boundary rather than at sample end.
            let framesPerInterval = AVAudioFrameCount(beat.samplesPerSubdivision)
            beat.buffer.frameLength = min(beat.buffer.frameCapacity, framesPerInterval)

            let capturedIsBeat = beat.isBeat
            let capturedInterval = beat.beatInterval
            let capturedRampedBpm = beat.rampedBpm
            let node = beat.isBeat ? beatNode : rhythmNode
            let when = AVAudioTime(sampleTime: nextBeatSampleTime, atRate: sampleRate)

            node.scheduleBuffer(beat.buffer, at: when, options: []) { [weak self] in
                DispatchQueue.main.async {
                    guard let self, self.sessionID == capturedSession else { return }
                    if let newBpm = capturedRampedBpm {
                        self.delegate?.metronomeRampStepped(newBpm: newBpm)
                    }
                    self.delegate?.metronomeBeatFired(isBeat: capturedIsBeat, beatInterval: capturedInterval)
                    self.scheduledCount -= 1
                    self.scheduleNextBeats()
                }
            }

            nextBeatSampleTime += AVAudioFramePosition(beat.samplesPerSubdivision)
            scheduledCount += 1
        }
    }
}
