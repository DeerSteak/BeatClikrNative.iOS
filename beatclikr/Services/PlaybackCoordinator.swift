//
//  PlaybackCoordinator.swift
//  beatclikr
//
//  created by Ben Funk 7/27/26
//

import Foundation

enum PlaybackMode: Equatable {
    case metronome
    case polyrhythm
}

@MainActor
final class PlaybackCoordinator: AudioPlaybackService {
    private let audio: any AudioPlaybackService

    private(set) var activeMode: PlaybackMode?
    var onMetronomeStopped: (() -> Void)?
    var onPolyrhythmStopped: (() -> Void)?

    var metronomeDelegate: MetronomeAudioEngineDelegate? {
        get { audio.metronomeDelegate }
        set { audio.metronomeDelegate = newValue }
    }

    var polyrhythmDelegate: PolyrhythmAudioEngineDelegate? {
        get { audio.polyrhythmDelegate }
        set { audio.polyrhythmDelegate = newValue }
    }

    init(audio: any AudioPlaybackService = AudioPlayerService.instance) {
        self.audio = audio
    }

    func setupMetronomeAudio(beatName: String, rhythmName: String) throws {
        try audio.setupMetronomeAudio(beatName: beatName, rhythmName: rhythmName)
    }

    func setupPolyrhythmAudio(beatName: String, rhythmName: String) throws {
        try audio.setupPolyrhythmAudio(beatName: beatName, rhythmName: rhythmName)
    }

    func setSoundBank(_ bank: SoundBank) {
        audio.setSoundBank(bank)
    }

    func startMetronome(bpm: Double, subdivisions: Int, accentPattern: [Bool]?) throws {
        if activeMode == .polyrhythm {
            stopPolyrhythm(notifyOwner: true)
        }
        try audio.startMetronome(bpm: bpm, subdivisions: subdivisions, accentPattern: accentPattern)
        activeMode = .metronome
    }

    func stopMetronome() {
        stopMetronome(notifyOwner: false)
    }

    private func stopMetronome(notifyOwner: Bool) {
        audio.stopMetronome()
        if activeMode == .metronome {
            activeMode = nil
        }
        if notifyOwner {
            onMetronomeStopped?()
        }
    }

    func updateTempo(bpm: Double, subdivisions: Int) {
        audio.updateTempo(bpm: bpm, subdivisions: subdivisions)
    }

    func setRamp(enabled: Bool, increment: Int, interval: Int) {
        audio.setRamp(enabled: enabled, increment: increment, interval: interval)
    }

    func startPolyrhythm(bpm: Double, beats: Int, against: Int) throws {
        if activeMode == .metronome {
            stopMetronome(notifyOwner: true)
        }
        try audio.startPolyrhythm(bpm: bpm, beats: beats, against: against)
        activeMode = .polyrhythm
    }

    func stopPolyrhythm() {
        stopPolyrhythm(notifyOwner: false)
    }

    private func stopPolyrhythm(notifyOwner: Bool) {
        audio.stopPolyrhythm()
        if activeMode == .polyrhythm {
            activeMode = nil
        }
        if notifyOwner {
            onPolyrhythmStopped?()
        }
    }

    func stopAll() {
        stopMetronome(notifyOwner: true)
        stopPolyrhythm(notifyOwner: true)
    }
}
