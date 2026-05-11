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
    private let playerNode = AVAudioPlayerNode()

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
        playerNode.stop()
        playerNode.play()

        currentBPM = bpm
        currentSubdivisions = subdivisions
        self.accentPattern = accentPattern
        self.delegate = delegate
        useAlternateSixteenth = UserDefaultsService.instance.sixteenthAlternate && subdivisions == 4
        currentSubdivision = 0
        patternIndex = 0
        scheduledCount = 0
        isPlaying = true

        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        nextBeatSampleTime = AVAudioFramePosition(sampleRate * MetronomeConstants.firstBeatDelay)

        scheduleNextBeats()
    }

    func stopMetronome() {
        sessionID += 1
        isPlaying = false
        playerNode.stop()
        scheduledCount = 0
        currentSubdivision = 0
        patternIndex = 0
    }

    func updateTempo(bpm: Double, subdivisions: Int) {
        currentBPM = bpm
        currentSubdivisions = subdivisions
        useAlternateSixteenth = UserDefaultsService.instance.sixteenthAlternate && subdivisions == 4
        // Already-scheduled buffers drain naturally; new ones use the updated tempo
    }

    func start() throws {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        try engine.start()
    }

    func stop() {
        playerNode.stop()
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
    }

    private func nextBeat() -> ScheduledBeat? {
        let subdivisionsPerSecond = (currentBPM / 60.0) * Double(currentSubdivisions)
        let subdivisionDuration = 1.0 / subdivisionsPerSecond

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
            return ScheduledBeat(buffer: audio, isBeat: isBeat, beatInterval: beatInterval)
        } else {
            let isBeat = currentSubdivision == 0
            let playBeat = useAlternateSixteenth ? currentSubdivision % 2 == 0 : currentSubdivision == 0
            guard let audio = playBeat ? beatBuffer : rhythmBuffer else { return nil }
            let beatInterval = 60.0 / currentBPM
            currentSubdivision = (currentSubdivision + 1) % currentSubdivisions
            return ScheduledBeat(buffer: audio, isBeat: isBeat, beatInterval: beatInterval)
        }
    }

    private func scheduleNextBeats() {
        guard isPlaying else { return }

        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate
        let subdivisionsPerSecond = (currentBPM / 60.0) * Double(currentSubdivisions)
        let samplesPerSubdivision = sampleRate / subdivisionsPerSecond

        playerNode.volume = UserDefaultsService.instance.muteMetronome ? 0 : 1

        // Cap buffer playback length to the interval so callbacks fire on schedule.
        // frameCapacity is the full sample length; frameLength is what the player reads.
        let framesPerInterval = AVAudioFrameCount(samplesPerSubdivision)
        if let buf = beatBuffer { buf.frameLength = min(buf.frameCapacity, framesPerInterval) }
        if let buf = rhythmBuffer { buf.frameLength = min(buf.frameCapacity, framesPerInterval) }

        let capturedSession = sessionID

        while scheduledCount < scheduleAheadCount {
            guard let beat = nextBeat() else { break }

            let capturedIsBeat = beat.isBeat
            let capturedInterval = beat.beatInterval
            let when = AVAudioTime(sampleTime: nextBeatSampleTime, atRate: sampleRate)

            playerNode.scheduleBuffer(beat.buffer, at: when, options: []) { [weak self] in
                DispatchQueue.main.async {
                    guard let self, self.sessionID == capturedSession else { return }
                    self.delegate?.metronomeBeatFired(isBeat: capturedIsBeat, beatInterval: capturedInterval)
                    self.scheduledCount -= 1
                    self.scheduleNextBeats()
                }
            }

            nextBeatSampleTime += AVAudioFramePosition(samplesPerSubdivision)
            scheduledCount += 1
        }
    }
}
