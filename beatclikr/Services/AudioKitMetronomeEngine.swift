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
class AudioKitMetronomeEngine: MetronomeAudioEngine, @unchecked Sendable {
    private let engine: AudioEngine
    nonisolated(unsafe) private let sampler = AppleSampler()

    nonisolated(unsafe) private var beatSound: SoundFile?
    nonisolated(unsafe) private var rhythmSound: SoundFile?
    nonisolated(unsafe) private weak var delegate: MetronomeAudioEngineDelegate?

    // All scheduling state is accessed exclusively on schedulingQueue
    private let schedulingQueue = DispatchQueue(
        label: "com.beatclikr.metronome",
        qos: .userInteractive
    )
    private var isPlaying = false
    private var currentBPM: Double = 60
    private var currentSubdivisions: Int = 1
    private var sourceTimer: DispatchSourceTimer?
    private var nextBeatTime: CFAbsoluteTime = 0
    private var subdivisionCounter: Int = 0

    private let checkInterval: TimeInterval = MetronomeConstants.timerCheckInterval
    private let firstBeatDelay: TimeInterval = MetronomeConstants.firstBeatDelay
    private let lookaheadTolerance: TimeInterval = MetronomeConstants.lookaheadTolerance

    init(engine: AudioEngine) {
        self.engine = engine
        engine.output = sampler
    }

    func loadSounds(beatName: String, rhythmName: String, from sounds: [SoundFile]) {
        beatSound = sounds.first { $0.displayName == beatName }
        rhythmSound = sounds.first { $0.displayName == rhythmName }

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
        schedulingQueue.async { [weak self] in
            guard let self else { return }
            self.stopSourceTimer()
            self.delegate = delegate
            self.currentBPM = bpm
            self.currentSubdivisions = subdivisions
            self.subdivisionCounter = 0
            self.nextBeatTime = CFAbsoluteTimeGetCurrent() + self.firstBeatDelay
            self.isPlaying = true
            self.startSourceTimer()
        }
    }

    func stopMetronome() {
        schedulingQueue.async { [weak self] in
            guard let self else { return }
            self.isPlaying = false
            self.stopSourceTimer()
            self.subdivisionCounter = 0
        }
    }

    func updateTempo(bpm: Double, subdivisions: Int) {
        schedulingQueue.async { [weak self] in
            self?.currentBPM = bpm
            self?.currentSubdivisions = subdivisions
        }
    }

    func start() throws {
        try engine.start()
    }

    func stop() {
        engine.stop()
    }

    // MARK: - Private helpers (must be called from schedulingQueue)

    private func getSubdivisionDuration() -> Double {
        60.0 / (currentBPM * Double(currentSubdivisions))
    }

    private func startSourceTimer() {
        let timer = DispatchSource.makeTimerSource(queue: schedulingQueue)
        timer.schedule(deadline: .now(), repeating: checkInterval, leeway: .microseconds(500))
        timer.setEventHandler { [weak self] in
            self?.checkAndPlayBeat()
        }
        timer.resume()
        sourceTimer = timer
    }

    private func stopSourceTimer() {
        sourceTimer?.cancel()
        sourceTimer = nil
    }

    private func checkAndPlayBeat() {
        guard isPlaying else {
            stopSourceTimer()
            return
        }

        let now = CFAbsoluteTimeGetCurrent()

        if now >= nextBeatTime - lookaheadTolerance {
            playCurrentBeat()

            nextBeatTime = now + getSubdivisionDuration()

            subdivisionCounter += 1
            if subdivisionCounter >= currentSubdivisions {
                subdivisionCounter = 0
            }
        }
    }

    private func playCurrentBeat() {
        let isBeat = subdivisionCounter == 0

        if !UserDefaults.standard.bool(forKey: PreferenceKeys.muteMetronome) {
            if isBeat, let beatSound {
                sampler.play(noteNumber: MIDINoteNumber(beatSound.midiNote))
            } else if !isBeat, let rhythmSound {
                sampler.play(noteNumber: MIDINoteNumber(rhythmSound.midiNote))
            }
        }

        // Hop back to main actor for UI/animation callbacks
        Task { @MainActor [weak self] in
            self?.delegate?.metronomeBeatFired(isBeat: isBeat)
        }
    }
}
