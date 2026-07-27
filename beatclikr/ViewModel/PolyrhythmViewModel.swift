//
//  PolyrhythmViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 5/3/26.
//

import Combine
import Foundation
import QuartzCore
import SwiftUI

@MainActor
final class PolyrhythmViewModel: ObservableObject, PolyrhythmAudioEngineDelegate {
    var onPlaybackStarted: (() -> Void)?
    var onPlaybackEnded: (() -> Void)?

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

    @Published private(set) var playbackState: PlaybackState = .idle

    var isPlaying: Bool {
        playbackState == .playing
    }

    var playbackError: PlaybackError? {
        guard case let .failed(error) = playbackState else { return nil }
        return error
    }

    @Published var beat: FileConstants {
        didSet {
            if !applyingSettingsChange {
                settings.updatePolyrhythmBeat(beat)
            }
            restartForSoundChangeIfNeeded()
        }
    }

    @Published var rhythm: FileConstants {
        didSet {
            if !applyingSettingsChange {
                settings.updatePolyrhythmRhythm(rhythm)
            }
            restartForSoundChangeIfNeeded()
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

    private let audio: any AudioPlaybackService
    private let settings: SettingsViewModel
    private var settingsCancellables: Set<AnyCancellable> = []
    private var applyingSettingsChange = false
    private let visualAnimator = PolyrhythmVisualAnimator()

    // MARK: - Init

    init(
        audio: any AudioPlaybackService = AudioPlayerService.instance,
        settings: SettingsViewModel = SettingsViewModel(),
        reduceMotionEnabled: @escaping () -> Bool = { UIAccessibility.isReduceMotionEnabled },
    ) {
        self.audio = audio
        self.settings = settings
        beats = settings.polyrhythmBeats
        against = settings.polyrhythmAgainst
        bpm = settings.polyrhythmBpm
        beat = settings.polyrhythmBeat
        rhythm = settings.polyrhythmRhythm
        audio.polyrhythmDelegate = self
        visualAnimator.onUpdate = { [weak self] beatPulse, rhythmPulse, cycleProgress in
            self?.beatPulse = beatPulse
            self?.rhythmPulse = rhythmPulse
            self?.cycleProgress = cycleProgress
        }
        visualAnimator.playbackTime = { [weak audio] in
            audio?.polyrhythmPlaybackTime()
        }
        visualAnimator.reduceMotionEnabled = reduceMotionEnabled
        observeSettings()
    }

    // MARK: - PolyrhythmAudioEngineDelegate

    func polyrhythmBeatFired(beatFired: Bool, rhythmFired: Bool, beatIndex: Int, rhythmIndex: Int) {
        let quarterDuration = 60.0 / bpm

        if beatFired {
            activeBeatIndex = beatIndex
            visualAnimator.notifyBeat(interval: quarterDuration)
            if beatIndex == 0 {
                let cycleDuration = Double(against) * quarterDuration
                visualAnimator.notifyCycleStart(duration: cycleDuration)
            }
        }

        if rhythmFired {
            activeRhythmIndex = rhythmIndex
            let rhythmInterval = Double(against) * quarterDuration / Double(beats)
            visualAnimator.notifyRhythm(interval: rhythmInterval)
        }
    }

    // MARK: - Playback control

    func togglePlayPause() {
        if isPlaying { stop() } else { start() }
    }

    func start() {
        guard beats >= 1, against >= 1, bpm > 0 else {
            playbackState = .failed(.invalidConfiguration)
            return
        }

        playbackState = .preparing
        playheadResetID += 1
        resetCycleProgress()
        do {
            try audio.setupPolyrhythmAudio(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
            try audio.startPolyrhythm(bpm: bpm, beats: beats, against: against)
            visualAnimator.start()
            playbackState = .playing
            onPlaybackStarted?()
        } catch {
            audio.stopPolyrhythm()
            visualAnimator.stop()
            resetCycleProgress()
            playbackState = .failed(Self.playbackError(from: error))
        }
    }

    func stop() {
        let wasPlaying = isPlaying
        playheadResetID += 1
        audio.stopPolyrhythm()
        visualAnimator.stop()
        playbackState = .idle
        if wasPlaying { onPlaybackEnded?() }
        resetCycleProgress()
    }

    func dismissPlaybackError() {
        guard playbackError != nil else { return }
        playbackState = .idle
    }

    func playbackWasStoppedByCoordinator() {
        let wasPlaying = isPlaying
        playheadResetID += 1
        visualAnimator.stop()
        playbackState = .idle
        if wasPlaying { onPlaybackEnded?() }
        resetCycleProgress()
    }

    func playbackWasInterrupted() {
        let wasPlaying = isPlaying
        visualAnimator.stop()
        playbackState = .interrupted
        if wasPlaying { onPlaybackEnded?() }
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

        settings.$soundBank
            .dropFirst()
            .sink { [weak self] bank in
                guard let self else { return }
                audio.setSoundBank(bank)
                restartForSoundChangeIfNeeded()
            }
            .store(in: &settingsCancellables)
    }

    private func applySettingsChange(_ update: () -> Void) {
        applyingSettingsChange = true
        update()
        applyingSettingsChange = false
    }

    private func restartForSoundChangeIfNeeded() {
        guard isPlaying else { return }
        start()
    }

    private static func playbackError(from error: Error) -> PlaybackError {
        error as? PlaybackError ?? .engineStartFailed
    }
}
