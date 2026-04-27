//
//  AudioPlayerService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/12/23.
//

import Foundation
import AudioKit
import AVFoundation

@MainActor
class AudioPlayerService: HasAudioEngine, MetronomeAudioEngineDelegate {
    static let instance = AudioPlayerService()

    nonisolated(unsafe) internal let engine = AudioEngine()

    private let audioEngine: MetronomeAudioEngine

    var sounds: [SoundFile]

    weak var delegate: MetronomeAudioEngineDelegate?

    init() {
        // Use AudioKit's AppleSampler for sample-accurate timing
        // Works on both simulator and device
        audioEngine = AVAudioMetronomeEngine(engine: engine)

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
            if file != FileConstants.Silence && file != FileConstants.FileExt {
                let sound = SoundFile(file.rawValue, file: "\(file.rawValue).\(FileConstants.FileExt.rawValue)", note: file.getNoteNumber())
                sounds.append(sound)
            }
        }

        // Start the audio engine
        do {
            try audioEngine.start()
        } catch {
            print("Can't start engine: \(error)")
        }
    }

    // MARK: - Public API

    /// Load the beat and rhythm sounds
    func setupAudioPlayer(beatName: String, rhythmName: String) {
        audioEngine.loadSounds(beatName: beatName, rhythmName: rhythmName, from: sounds)
    }

    /// Start the metronome with the given tempo and subdivisions
    func startMetronome(bpm: Double, subdivisions: Int) {
        audioEngine.startMetronome(bpm: bpm, subdivisions: subdivisions, delegate: self)
    }

    /// Stop the metronome
    func stopMetronome() {
        audioEngine.stopMetronome()
    }

    /// Update the tempo while playing
    func updateTempo(bpm: Double, subdivisions: Int) {
        audioEngine.updateTempo(bpm: bpm, subdivisions: subdivisions)
    }

    // MARK: - MetronomeAudioEngineDelegate

    func metronomeBeatFired(isBeat: Bool) {
        // Forward to external delegate (ViewModel)
        delegate?.metronomeBeatFired(isBeat: isBeat)
    }
}
