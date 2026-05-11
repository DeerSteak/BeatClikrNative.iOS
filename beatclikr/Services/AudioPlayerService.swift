//
//  AudioPlayerService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/12/23.
//

import AudioKit
import AVFoundation
import Foundation

@MainActor
class AudioPlayerService: HasAudioEngine, MetronomeAudioEngineDelegate, PolyrhythmAudioEngineDelegate {
    static let instance = AudioPlayerService()

    // AudioKit engine kept for polyrhythm and as fallback for the legacy metronome engine
    nonisolated(unsafe) let engine = AudioEngine()
    private let sampler = AppleSampler()

    /// Scheduled engine: sample-accurate, no timer polling (Phase 2)
    private let scheduledMetronomeEngine = ScheduledMetronomeEngine()
    /// Legacy engine: timer-based fallback (Phase 1); kept for future settings toggle
    private let legacyMetronomeEngine: AudioKitMetronomeEngine

    // Future: switch between engines via a user setting
    private var audioEngine: MetronomeAudioEngine {
        scheduledMetronomeEngine
    }

    private let polyEngine: PolyrhythmAudioEngine

    var sounds: [SoundFile]

    weak var delegate: MetronomeAudioEngineDelegate?
    weak var polyrhythmDelegate: PolyrhythmAudioEngineDelegate?

    init() {
        engine.output = sampler
        legacyMetronomeEngine = AudioKitMetronomeEngine(engine: engine, sampler: sampler)
        polyEngine = AudioKitPolyrhythmEngine(sampler: sampler)

        // Configure audio session
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        // Load all sound files
        sounds = [SoundFile]()
        for file in FileConstants.allCases {
            if file != FileConstants.Silence, file != FileConstants.FileExt {
                let sound = SoundFile(file.rawValue, file: "\(file.rawValue).\(FileConstants.FileExt.rawValue)", note: file.getNoteNumber())
                sounds.append(sound)
            }
        }

        // Start the scheduled metronome engine (native AVAudioEngine)
        do {
            try scheduledMetronomeEngine.start()
        } catch {
            print("Can't start scheduled engine: \(error)")
        }

        // Start the AudioKit engine for polyrhythm
        do {
            try engine.start()
        } catch {
            print("Can't start AudioKit engine: \(error)")
        }
    }

    // MARK: - Public API

    func setupAudioPlayer(beatName: String, rhythmName: String) {
        scheduledMetronomeEngine.loadSounds(beatName: beatName, rhythmName: rhythmName, from: sounds)
        // Load the legacy engine's sampler so polyrhythm (which shares it) has sounds ready
        legacyMetronomeEngine.loadSounds(beatName: beatName, rhythmName: rhythmName, from: sounds)
        polyEngine.loadSounds(beatName: beatName, rhythmName: rhythmName, from: sounds)
    }

    /// Start the metronome with the given tempo, subdivisions, and optional accent pattern
    func startMetronome(bpm: Double, subdivisions: Int, accentPattern: [Bool]? = nil) {
        audioEngine.startMetronome(bpm: bpm, subdivisions: subdivisions, accentPattern: accentPattern, delegate: self)
    }

    /// Stop the metronome
    func stopMetronome() {
        audioEngine.stopMetronome()
    }

    /// Update the tempo while playing
    func updateTempo(bpm: Double, subdivisions: Int) {
        audioEngine.updateTempo(bpm: bpm, subdivisions: subdivisions)
    }

    /// Start the polyrhythm engine
    func startPolyrhythm(bpm: Double, beats: Int, against: Int) {
        polyEngine.startPolyrhythm(bpm: bpm, beats: beats, against: against, delegate: self)
    }

    /// Stop the polyrhythm engine
    func stopPolyrhythm() {
        polyEngine.stopPolyrhythm()
    }

    // MARK: - MetronomeAudioEngineDelegate

    func metronomeBeatFired(isBeat: Bool, beatInterval: TimeInterval) {
        delegate?.metronomeBeatFired(isBeat: isBeat, beatInterval: beatInterval)
    }

    // MARK: - PolyrhythmAudioEngineDelegate

    func polyrhythmBeatFired(beatFired: Bool, rhythmFired: Bool, beatIndex: Int, rhythmIndex: Int) {
        polyrhythmDelegate?.polyrhythmBeatFired(beatFired: beatFired, rhythmFired: rhythmFired, beatIndex: beatIndex, rhythmIndex: rhythmIndex)
    }
}
