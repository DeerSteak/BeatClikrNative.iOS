//
//  AudioKitMetronomeEngine.swift
//  beatclikr
//
//  Created by Ben Funk on 4/10/26.
//

import Foundation
import AudioKit
import AVFoundation

/// Sample-accurate metronome implementation using AudioKit's AppleSampler
/// Works on both simulator and device with high-precision timing (<5ms jitter)
@MainActor
class AudioKitMetronomeEngine: MetronomeAudioEngine {
    private let engine: AudioEngine
    private let sampler = AppleSampler()

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

    // Use smaller check interval for tighter timing on device
    private var checkInterval: TimeInterval = 0.001 // 1ms checks

    init(engine: AudioEngine) {
        self.engine = engine
        engine.output = sampler
    }

    func loadSounds(beatName: String, rhythmName: String, from sounds: [SoundFile]) {
        self.sounds = sounds
        self.beatSound = sounds.first { $0.displayName == beatName }
        self.rhythmSound = sounds.first { $0.displayName == rhythmName }

        do {
            let files = sounds.compactMap { $0.audioFile }
            if files.count != sounds.count {
                print("Warning: Only loaded \(files.count) of \(sounds.count) sound files")
            }
            try sampler.loadAudioFiles(files)
        } catch {
            print("Failed to load audio files: \(error)")
        }
    }

    func startMetronome(bpm: Double, subdivisions: Int, delegate: MetronomeAudioEngineDelegate) {
        self.delegate = delegate
        self.currentBPM = bpm
        self.currentSubdivisions = subdivisions
        self.isPlaying = true
        self.subdivisionCounter = 0
        self.nextBeatTime = CFAbsoluteTimeGetCurrent()

        startTimer()
    }

    func stopMetronome() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        subdivisionCounter = 0
    }

    func updateTempo(bpm: Double, subdivisions: Int) {
        self.currentBPM = bpm
        self.currentSubdivisions = subdivisions
        // Tempo change takes effect on next subdivision
    }

    func start() throws {
        try engine.start()
    }

    func stop() {
        engine.stop()
    }

    // MARK: - Private helpers

    private func getSubdivisionDuration() -> Double {
        return 60.0 / (currentBPM * Double(currentSubdivisions))
    }

    private func startTimer() {
        timer?.invalidate()

        // High-precision timer for device
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

        // Check if it's time to play the next beat (with small lookahead tolerance)
        if now >= nextBeatTime - 0.002 { // 2ms lookahead
            playCurrentBeat()

            // Schedule next beat
            let subdivisionDuration = getSubdivisionDuration()
            nextBeatTime = now + subdivisionDuration

            subdivisionCounter += 1
            if subdivisionCounter >= currentSubdivisions {
                subdivisionCounter = 0
            }
        }
    }

    private func playCurrentBeat() {
        let isBeat = subdivisionCounter == 0

        // Play the appropriate sample
        if isBeat {
            if let beatSound = beatSound {
                sampler.play(noteNumber: MIDINoteNumber(beatSound.midiNote))
            }
        } else {
            if let rhythmSound = rhythmSound {
                sampler.play(noteNumber: MIDINoteNumber(rhythmSound.midiNote))
            }
        }

        // Notify delegate for UI updates
        delegate?.metronomeBeatFired(isBeat: isBeat)
    }
}
