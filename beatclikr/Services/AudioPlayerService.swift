//
//  AudioPlayerService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/12/23.
//

import AVFoundation
import Foundation

@MainActor
class AudioPlayerService: MetronomeAudioEngineDelegate, PolyrhythmAudioEngineDelegate {
    static let instance = AudioPlayerService()

    private let metronomeEngine = ScheduledMetronomeEngine()
    private let polyEngine = ScheduledPolyrhythmEngine()

    var sounds: [SoundFile]

    weak var delegate: MetronomeAudioEngineDelegate?
    weak var polyrhythmDelegate: PolyrhythmAudioEngineDelegate?

    init() {
        // Configure audio session
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        // Load all sound files
        sounds = FileConstants.allCases.compactMap { file in
            guard file != .Silence, file != .FileExt else { return nil }
            return SoundFile(file.rawValue, file: "\(file.rawValue).\(FileConstants.FileExt.rawValue)", note: file.getNoteNumber())
        }

        do {
            try metronomeEngine.start()
        } catch {
            print("Can't start metronome engine: \(error)")
        }

        do {
            try polyEngine.start()
        } catch {
            print("Can't start polyrhythm engine: \(error)")
        }
    }

    // MARK: - Public API

    func setupAudioPlayer(beatName: String, rhythmName: String) {
        metronomeEngine.loadSounds(beatName: beatName, rhythmName: rhythmName, from: sounds)
        polyEngine.loadSounds(beatName: beatName, rhythmName: rhythmName, from: sounds)
    }

    func startMetronome(bpm: Double, subdivisions: Int, accentPattern: [Bool]? = nil) {
        metronomeEngine.startMetronome(bpm: bpm, subdivisions: subdivisions, accentPattern: accentPattern, delegate: self)
    }

    func stopMetronome() {
        metronomeEngine.stopMetronome()
    }

    func updateTempo(bpm: Double, subdivisions: Int) {
        metronomeEngine.updateTempo(bpm: bpm, subdivisions: subdivisions)
    }

    func setRamp(enabled: Bool, increment: Int, interval: Int) {
        metronomeEngine.setRamp(enabled: enabled, increment: increment, interval: interval)
    }

    func startPolyrhythm(bpm: Double, beats: Int, against: Int) {
        polyEngine.startPolyrhythm(bpm: bpm, beats: beats, against: against, delegate: self)
    }

    func stopPolyrhythm() {
        polyEngine.stopPolyrhythm()
    }

    // MARK: - MetronomeAudioEngineDelegate

    func metronomeBeatFired(isBeat: Bool, beatInterval: TimeInterval) {
        delegate?.metronomeBeatFired(isBeat: isBeat, beatInterval: beatInterval)
    }

    func metronomeRampStepped(newBpm: Double) {
        delegate?.metronomeRampStepped(newBpm: newBpm)
    }

    // MARK: - PolyrhythmAudioEngineDelegate

    func polyrhythmBeatFired(beatFired: Bool, rhythmFired: Bool, beatIndex: Int, rhythmIndex: Int) {
        polyrhythmDelegate?.polyrhythmBeatFired(beatFired: beatFired, rhythmFired: rhythmFired, beatIndex: beatIndex, rhythmIndex: rhythmIndex)
    }
}
