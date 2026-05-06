//
//  PolyrhythmAudioEngine.swift
//  beatclikr
//
//  Created by Ben Funk on 5/1/26.
//

import Foundation

/// Protocol for polyrhythm audio playback engines.
@MainActor
protocol PolyrhythmAudioEngine {
    func loadSounds(beatName: String, rhythmName: String, from sounds: [SoundFile])
    func startPolyrhythm(bpm: Double, beats: Int, against: Int, delegate: PolyrhythmAudioEngineDelegate)
    func stopPolyrhythm()
}

/// Delegate for polyrhythm beat callbacks.
/// beatIndex is the index of the current beat (0..<against), rhythmIndex is the index of the current rhythm note (0..<beats).
/// Both indices are only meaningful when their corresponding fired flag is true.
@MainActor
protocol PolyrhythmAudioEngineDelegate: AnyObject {
    func polyrhythmBeatFired(beatFired: Bool, rhythmFired: Bool, beatIndex: Int, rhythmIndex: Int)
}
