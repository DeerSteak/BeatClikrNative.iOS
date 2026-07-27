//
//  AudioPlayerService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/12/23.
//

import AVFoundation
import Foundation
import OSLog

@MainActor
protocol AudioPlaybackService: AnyObject {
    var metronomeDelegate: MetronomeAudioEngineDelegate? { get set }
    var polyrhythmDelegate: PolyrhythmAudioEngineDelegate? { get set }

    func setupMetronomeAudio(beatName: String, rhythmName: String) throws
    func setupPolyrhythmAudio(beatName: String, rhythmName: String) throws
    func setSoundBank(_ bank: SoundBank)
    func startMetronome(bpm: Double, subdivisions: Int, accentPattern: [Bool]?) throws
    func stopMetronome()
    func updateTempo(bpm: Double, subdivisions: Int)
    func setRamp(enabled: Bool, increment: Int, interval: Int)
    func startPolyrhythm(bpm: Double, beats: Int, against: Int) throws
    func stopPolyrhythm()
}

@MainActor
class AudioPlayerService: AudioPlaybackService, MetronomeAudioEngineDelegate, PolyrhythmAudioEngineDelegate {
    static let instance = AudioPlayerService()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BeatClikr", category: "Playback")
    private let metronomeEngine = ScheduledMetronomeEngine()
    private let polyrhythmEngine = ScheduledPolyrhythmEngine()
    private var isAudioSessionReady = false
    private var isMetronomeEngineReady = false
    private var isPolyrhythmEngineReady = false

    var sounds: [SoundFile]
    private var activeSoundBank: SoundBank

    weak var metronomeDelegate: MetronomeAudioEngineDelegate?
    weak var polyrhythmDelegate: PolyrhythmAudioEngineDelegate?

    init() {
        activeSoundBank = UserDefaultsService.instance.soundBank
        sounds = Self.loadSounds(bank: activeSoundBank)
    }

    // MARK: - Public API

    func setupMetronomeAudio(beatName: String, rhythmName: String) throws {
        try prepareAudioSession()
        try prepareMetronomeEngine()
        reloadSoundsIfNeeded()
        try metronomeEngine.loadSounds(beatName: beatName, rhythmName: rhythmName, from: sounds)
    }

    func setupPolyrhythmAudio(beatName: String, rhythmName: String) throws {
        try prepareAudioSession()
        try preparePolyrhythmEngine()
        reloadSoundsIfNeeded()
        try polyrhythmEngine.loadSounds(beatName: beatName, rhythmName: rhythmName, from: sounds)
    }

    func setSoundBank(_ bank: SoundBank) {
        guard activeSoundBank != bank else { return }
        activeSoundBank = bank
        sounds = Self.loadSounds(bank: bank)
    }

    func startMetronome(bpm: Double, subdivisions: Int, accentPattern: [Bool]? = nil) throws {
        try metronomeEngine.startMetronome(bpm: bpm, subdivisions: subdivisions, accentPattern: accentPattern, delegate: self)
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

    func startPolyrhythm(bpm: Double, beats: Int, against: Int) throws {
        try polyrhythmEngine.startPolyrhythm(bpm: bpm, beats: beats, against: against, delegate: self)
    }

    func stopPolyrhythm() {
        polyrhythmEngine.stopPolyrhythm()
    }

    // MARK: - MetronomeAudioEngineDelegate

    func metronomeBeatFired(isBeat: Bool, beatInterval: TimeInterval) {
        metronomeDelegate?.metronomeBeatFired(isBeat: isBeat, beatInterval: beatInterval)
    }

    func metronomeRampStepped(newBpm: Double) {
        metronomeDelegate?.metronomeRampStepped(newBpm: newBpm)
    }

    // MARK: - PolyrhythmAudioEngineDelegate

    func polyrhythmBeatFired(beatFired: Bool, rhythmFired: Bool, beatIndex: Int, rhythmIndex: Int) {
        polyrhythmDelegate?.polyrhythmBeatFired(beatFired: beatFired, rhythmFired: rhythmFired, beatIndex: beatIndex, rhythmIndex: rhythmIndex)
    }

    // MARK: - Private

    private static func loadSounds(bank: SoundBank) -> [SoundFile] {
        FileConstants.allCases.compactMap { file in
            guard file != .Silence, file != .FileExt else { return nil }
            return SoundFile(file.rawValue, file: "\(file.rawValue).\(FileConstants.FileExt.rawValue)", note: file.getNoteNumber(), bank: bank)
        }
    }

    private func reloadSoundsIfNeeded() {
        setSoundBank(UserDefaultsService.instance.soundBank)
    }

    private func prepareAudioSession() throws {
        guard !isAudioSessionReady else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            isAudioSessionReady = true
        } catch {
            logger.error("Audio session setup failed: \(error, privacy: .public)")
            throw PlaybackError.audioSessionUnavailable
        }
    }

    private func prepareMetronomeEngine() throws {
        guard !isMetronomeEngineReady else { return }
        do {
            try metronomeEngine.start()
            isMetronomeEngineReady = true
        } catch {
            logger.error("Metronome engine start failed: \(error, privacy: .public)")
            throw PlaybackError.engineStartFailed
        }
    }

    private func preparePolyrhythmEngine() throws {
        guard !isPolyrhythmEngineReady else { return }
        do {
            try polyrhythmEngine.start()
            isPolyrhythmEngineReady = true
        } catch {
            logger.error("Polyrhythm engine start failed: \(error, privacy: .public)")
            throw PlaybackError.engineStartFailed
        }
    }
}
