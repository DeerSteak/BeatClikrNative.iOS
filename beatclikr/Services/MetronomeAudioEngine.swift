//
//  MetronomeAudioEngine.swift
//  beatclikr
//
//  Created by Ben Funk on 4/10/26.
//

import Foundation
import AudioKit

/// Protocol for metronome audio playback engines.
/// Abstracts the difference between simulator (AudioPlayer) and device (AppleSampler/Sequencer) implementations.
protocol MetronomeAudioEngine {
    /// Load the beat and rhythm sound files
    func loadSounds(beatName: String, rhythmName: String, from sounds: [SoundFile])

    /// Start the metronome with the given tempo and subdivisions
    func startMetronome(bpm: Double, subdivisions: Int, delegate: MetronomeAudioEngineDelegate)

    /// Stop the metronome
    func stopMetronome()

    /// Update the tempo while playing
    func updateTempo(bpm: Double, subdivisions: Int)

    /// Start the audio engine
    func start() throws

    /// Stop the audio engine
    func stop()
}

/// Delegate protocol for metronome beat callbacks
@MainActor
protocol MetronomeAudioEngineDelegate: AnyObject, Sendable {
    func metronomeBeatFired(isBeat: Bool)
}
