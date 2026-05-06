//
//  PolyrhythmViewModel.swift
//  beatclikr
//

import Foundation
import SwiftUI

@MainActor
class PolyrhythmViewModel: ObservableObject, PolyrhythmAudioEngineDelegate {

    // MARK: - Published properties

    @Published var beats: Int {
        didSet {
            defaults.polyrhythmBeats = beats
            if isPlaying { start() }
        }
    }

    @Published var against: Int {
        didSet {
            defaults.polyrhythmAgainst = against
            if isPlaying { start() }
        }
    }

    @Published var bpm: Double {
        didSet {
            defaults.polyrhythmBpm = bpm
            if isPlaying { start() }
        }
    }

    @Published var isPlaying = false

    @Published var beat: FileConstants {
        didSet {
            defaults.polyrhythmBeat = beat
            audio.setupAudioPlayer(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
        }
    }

    @Published var rhythm: FileConstants {
        didSet {
            defaults.polyrhythmRhythm = rhythm
            audio.setupAudioPlayer(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
        }
    }

    /// 0–1 pulse driven by beat (quarter-note) firings
    @Published var beatPulse: Double = 0
    /// 0–1 pulse driven by rhythm firings
    @Published var rhythmPulse: Double = 0
    /// Which beat dot (0..<against) is currently active
    @Published var activeBeatIndex: Int = 0
    /// Which rhythm dot (0..<beats) is currently active
    @Published var activeRhythmIndex: Int = 0
    /// 0–1 progress through one full cycle, animates smoothly for the playhead
    @Published var cycleProgress: Double = 0

    // MARK: - Private

    private let audio: AudioPlayerService
    private let defaults: UserDefaultsService

    // MARK: - Init

    init(audio: AudioPlayerService = .instance, defaults: UserDefaultsService = .instance) {
        self.audio = audio
        self.defaults = defaults
        beats = defaults.polyrhythmBeats
        against = defaults.polyrhythmAgainst
        bpm = defaults.polyrhythmBpm
        beat = defaults.polyrhythmBeat
        rhythm = defaults.polyrhythmRhythm
        audio.polyrhythmDelegate = self
    }

    // MARK: - PolyrhythmAudioEngineDelegate

    func polyrhythmBeatFired(beatFired: Bool, rhythmFired: Bool, beatIndex: Int, rhythmIndex: Int) {
        let quarterDuration = 60.0 / bpm

        if beatFired {
            activeBeatIndex = beatIndex
            withAnimation(.none) { beatPulse = 1.0 }
            Task { @MainActor in
                withAnimation(.linear(duration: quarterDuration)) { self.beatPulse = 0.0 }
            }
            if beatIndex == 0 {
                let cycleDuration = Double(against) * quarterDuration
                withAnimation(.none) { cycleProgress = 0.0 }
                Task { @MainActor in
                    withAnimation(.linear(duration: cycleDuration)) { self.cycleProgress = 1.0 }
                }
            }
        }

        if rhythmFired {
            activeRhythmIndex = rhythmIndex
            let rhythmInterval = Double(against) * quarterDuration / Double(beats)
            withAnimation(.none) { rhythmPulse = 1.0 }
            Task { @MainActor in
                withAnimation(.linear(duration: rhythmInterval)) { self.rhythmPulse = 0.0 }
            }
        }
    }

    // MARK: - Playback control

    func onAppear() {
        UIApplication.shared.isIdleTimerDisabled = defaults.keepAwake
    }

    func togglePlayPause() {
        if isPlaying { stop() } else { start() }
    }

    func start() {
        audio.setupAudioPlayer(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
        audio.startPolyrhythm(bpm: bpm, beats: beats, against: against)
        isPlaying = true
    }

    func stop() {
        audio.stopPolyrhythm()
        isPlaying = false
        cycleProgress = 0
    }
}
