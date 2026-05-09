//
//  PolyrhythmViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 5/3/26.
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
    private var playbackGeneration = 0

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
                let generation = playbackGeneration
                resetCycleProgress()
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(16))
                    guard self.isPlaying, self.playbackGeneration == generation else { return }
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
        playbackGeneration += 1
        resetCycleProgress()
        audio.setupAudioPlayer(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
        audio.startPolyrhythm(bpm: bpm, beats: beats, against: against)
        isPlaying = true
    }

    func stop() {
        playbackGeneration += 1
        audio.stopPolyrhythm()
        isPlaying = false
        resetCycleProgress()
    }

    private func resetCycleProgress() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            cycleProgress = 0
        }
    }
}
