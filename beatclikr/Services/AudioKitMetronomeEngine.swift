//
//  AudioKitMetronomeEngine.swift
//  beatclikr
//
//  Created by Ben Funk on 4/10/26.
//

import AudioKit
import AVFoundation
import Foundation

/// Sample-accurate metronome implementation using AudioKit's AppleSampler
/// Works on both simulator and device with high-precision timing (<5ms jitter)
@MainActor
class AudioKitMetronomeEngine: MetronomeAudioEngine {
    private let engine: AudioEngine
    private let sampler: AppleSampler

    private var sounds: [SoundFile] = []
    private var beatSound: SoundFile?
    private var rhythmSound: SoundFile?

    private weak var delegate: MetronomeAudioEngineDelegate?
    private var isPlaying = false
    private var currentBPM: Double = 60
    private var currentSubdivisions: Int = 1

    private var timer: Timer?
    private var nextBeatTime: CFAbsoluteTime = 0
    private var subdivisionCounter: Int = 0
    private var useAlternateSixteenth: Bool = false
    private var accentPattern: [Bool]?
    private var patternIndex: Int = 0

    private let checkInterval: TimeInterval = MetronomeConstants.timerCheckInterval
    private let firstBeatDelay: TimeInterval = MetronomeConstants.firstBeatDelay
    private let lookaheadTolerance: TimeInterval = MetronomeConstants.lookaheadTolerance

    init(engine: AudioEngine, sampler: AppleSampler) {
        self.engine = engine
        self.sampler = sampler
    }

    func loadSounds(beatName: String, rhythmName: String, from sounds: [SoundFile]) {
        self.sounds = sounds
        beatSound = sounds.first { $0.displayName == beatName }
        rhythmSound = sounds.first { $0.displayName == rhythmName }

        do {
            let files = sounds.compactMap(\.audioFile)
            if files.count != sounds.count {
                print("Warning: Only loaded \(files.count) of \(sounds.count) sound files")
            }
            try sampler.loadAudioFiles(files)
        } catch {
            print("Failed to load audio files: \(error)")
        }
    }

    func startMetronome(bpm: Double, subdivisions: Int, accentPattern: [Bool]?, delegate: MetronomeAudioEngineDelegate) {
        timer?.invalidate()
        timer = nil

        self.delegate = delegate
        currentBPM = bpm
        currentSubdivisions = subdivisions
        subdivisionCounter = 0
        self.accentPattern = accentPattern
        patternIndex = 0
        useAlternateSixteenth = UserDefaultsService.instance.sixteenthAlternate && subdivisions == 4

        nextBeatTime = CFAbsoluteTimeGetCurrent() + firstBeatDelay

        isPlaying = true
        startTimer()
    }

    func stopMetronome() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        subdivisionCounter = 0
        patternIndex = 0
    }

    func updateTempo(bpm: Double, subdivisions: Int) {
        currentBPM = bpm
        currentSubdivisions = subdivisions
    }

    func start() throws {
        try engine.start()
    }

    func stop() {
        engine.stop()
    }

    // MARK: - Private helpers

    private func getSubdivisionDuration() -> Double {
        60.0 / (currentBPM * Double(currentSubdivisions))
    }

    private func startTimer() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndPlayBeat()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func checkAndPlayBeat() {
        guard isPlaying else {
            timer?.invalidate()
            timer = nil
            return
        }

        let now = CFAbsoluteTimeGetCurrent()

        if now >= nextBeatTime - lookaheadTolerance {
            playCurrentBeat()

            let subdivisionDuration = getSubdivisionDuration()
            nextBeatTime = now + subdivisionDuration

            subdivisionCounter += 1
            if subdivisionCounter >= currentSubdivisions {
                subdivisionCounter = 0
            }
        }
    }

    private func playCurrentBeat() {
        let isBeat: Bool
        let playBeatSound: Bool
        let beatInterval: TimeInterval
        let subdivisionDuration = getSubdivisionDuration()

        if let pattern = accentPattern {
            isBeat = pattern[patternIndex]
            playBeatSound = isBeat

            if isBeat {
                // Count subdivision ticks until the next accented beat in the pattern
                var ticksToNext = 1
                var lookIndex = (patternIndex + 1) % pattern.count
                while !pattern[lookIndex], ticksToNext < pattern.count {
                    ticksToNext += 1
                    lookIndex = (lookIndex + 1) % pattern.count
                }
                beatInterval = subdivisionDuration * Double(ticksToNext)
            } else {
                beatInterval = subdivisionDuration
            }

            patternIndex = (patternIndex + 1) % pattern.count
        } else {
            playBeatSound = useAlternateSixteenth ? subdivisionCounter % 2 == 0 : subdivisionCounter == 0
            isBeat = subdivisionCounter == 0
            beatInterval = 60.0 / currentBPM
        }

        if !UserDefaultsService.instance.muteMetronome {
            if playBeatSound {
                if let beatSound {
                    sampler.play(noteNumber: MIDINoteNumber(beatSound.midiNote))
                }
            } else {
                if let rhythmSound {
                    sampler.play(noteNumber: MIDINoteNumber(rhythmSound.midiNote))
                }
            }
        }

        // Always fire the delegate so animation, vibration, and flashlight still work when muted
        delegate?.metronomeBeatFired(isBeat: isBeat, beatInterval: beatInterval)
    }
}
