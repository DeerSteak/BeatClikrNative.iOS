//
//  PolyrhythmViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 5/3/26.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class PolyrhythmViewModel: ObservableObject, PolyrhythmAudioEngineDelegate {
    // MARK: - Published properties

    @Published var beats: Int {
        didSet {
            if !applyingSettingsChange {
                settings.updatePolyrhythmBeats(beats)
            }
            if isPlaying { start() }
        }
    }

    @Published var against: Int {
        didSet {
            if !applyingSettingsChange {
                settings.updatePolyrhythmAgainst(against)
            }
            if isPlaying { start() }
        }
    }

    @Published var bpm: Double {
        didSet {
            if !applyingSettingsChange {
                settings.updatePolyrhythmBpm(bpm)
            }
            if isPlaying { start() }
        }
    }

    @Published var isPlaying = false

    @Published var beat: FileConstants {
        didSet {
            if !applyingSettingsChange {
                settings.updatePolyrhythmBeat(beat)
            }
            audio.setupAudioPlayer(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
        }
    }

    @Published var rhythm: FileConstants {
        didSet {
            if !applyingSettingsChange {
                settings.updatePolyrhythmRhythm(rhythm)
            }
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
    /// Forces the playhead view to discard stale in-flight animations after restarts.
    @Published private(set) var playheadResetID = 0

    // MARK: - Private

    private let audio: AudioPlayerService
    private let settings: SettingsViewModel
    private var settingsCancellables: Set<AnyCancellable> = []
    private var playbackGeneration = 0
    private var applyingSettingsChange = false

    // MARK: - Init

    init(audio: AudioPlayerService = .instance, settings: SettingsViewModel = SettingsViewModel()) {
        self.audio = audio
        self.settings = settings
        beats = settings.polyrhythmBeats
        against = settings.polyrhythmAgainst
        bpm = settings.polyrhythmBpm
        beat = settings.polyrhythmBeat
        rhythm = settings.polyrhythmRhythm
        audio.polyrhythmDelegate = self
        observeSettings()
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

    func togglePlayPause() {
        if isPlaying { stop() } else { start() }
    }

    func start() {
        guard beats >= 1, against >= 1, bpm > 0 else {
            stop()
            return
        }

        playbackGeneration += 1
        playheadResetID += 1
        resetCycleProgress()
        audio.setupAudioPlayer(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
        audio.startPolyrhythm(bpm: bpm, beats: beats, against: against)
        isPlaying = true
    }

    func stop() {
        playbackGeneration += 1
        playheadResetID += 1
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

    private func observeSettings() {
        settings.$polyrhythmBeats
            .dropFirst()
            .sink { [weak self] beats in
                guard let self, self.beats != beats else { return }
                applySettingsChange { self.beats = beats }
            }
            .store(in: &settingsCancellables)

        settings.$polyrhythmAgainst
            .dropFirst()
            .sink { [weak self] against in
                guard let self, self.against != against else { return }
                applySettingsChange { self.against = against }
            }
            .store(in: &settingsCancellables)

        settings.$polyrhythmBpm
            .dropFirst()
            .sink { [weak self] bpm in
                guard let self, self.bpm != bpm else { return }
                applySettingsChange { self.bpm = bpm }
            }
            .store(in: &settingsCancellables)

        settings.$polyrhythmBeat
            .dropFirst()
            .sink { [weak self] beat in
                guard let self, self.beat != beat else { return }
                applySettingsChange { self.beat = beat }
            }
            .store(in: &settingsCancellables)

        settings.$polyrhythmRhythm
            .dropFirst()
            .sink { [weak self] rhythm in
                guard let self, self.rhythm != rhythm else { return }
                applySettingsChange { self.rhythm = rhythm }
            }
            .store(in: &settingsCancellables)
    }

    private func applySettingsChange(_ update: () -> Void) {
        applyingSettingsChange = true
        update()
        applyingSettingsChange = false
    }
}
