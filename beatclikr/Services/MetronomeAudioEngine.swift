//
//  MetronomeAudioEngine.swift
//  beatclikr
//
//  Created by Ben Funk on 4/10/26.
//

import AudioKit
import Foundation

/// Protocol for metronome audio playback engines.
/// Abstracts the difference between simulator (AudioPlayer) and device (AppleSampler/Sequencer) implementations.
@MainActor
protocol MetronomeAudioEngine {
    /// Load the beat and rhythm sound files
    func loadSounds(beatName: String, rhythmName: String, from sounds: [SoundFile])

    /// Start the metronome with the given tempo, subdivisions, and optional accent pattern
    func startMetronome(bpm: Double, subdivisions: Int, accentPattern: [Bool]?, delegate: MetronomeAudioEngineDelegate)

    /// Stop the metronome
    func stopMetronome()

    /// Update the tempo while playing
    func updateTempo(bpm: Double, subdivisions: Int)

    /// Configure ramp parameters. Call before startMetronome or while playing.
    func setRamp(enabled: Bool, increment: Int, interval: Int)

    /// Start the audio engine
    func start() throws

    /// Stop the audio engine
    func stop()
}

/// Delegate protocol for metronome beat callbacks
@MainActor
protocol MetronomeAudioEngineDelegate: AnyObject {
    /// `beatInterval` is the time (in seconds) until the next accented beat fires,
    /// so animations can match the actual rhythmic group length.
    func metronomeBeatFired(isBeat: Bool, beatInterval: TimeInterval)

    /// Fired when the engine applies a ramp step during scheduling, carrying the new BPM.
    func metronomeRampStepped(newBpm: Double)
}
