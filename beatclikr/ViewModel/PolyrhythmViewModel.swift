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
            audio.setupPolyrhythmAudio(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
        }
    }

    @Published var rhythm: FileConstants {
        didSet {
            if !applyingSettingsChange {
                settings.updatePolyrhythmRhythm(rhythm)
            }
            audio.setupPolyrhythmAudio(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
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
    private var applyingSettingsChange = false
    private let visualAnimator = PolyrhythmVisualAnimator()

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
        visualAnimator.onUpdate = { [weak self] beatPulse, rhythmPulse, cycleProgress in
            self?.beatPulse = beatPulse
            self?.rhythmPulse = rhythmPulse
            self?.cycleProgress = cycleProgress
        }
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
            stop()
            return
        }

        playheadResetID += 1
        resetCycleProgress()
        visualAnimator.start()
        audio.setupPolyrhythmAudio(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
        audio.startPolyrhythm(bpm: bpm, beats: beats, against: against)
        isPlaying = true
    }

    func stop() {
        playheadResetID += 1
        audio.stopPolyrhythm()
        visualAnimator.stop()
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

private final class PolyrhythmVisualAnimator: NSObject {
    private var displayLink: CADisplayLink?
    private var lastBeatTime: CFTimeInterval = CACurrentMediaTime()
    private var lastRhythmTime: CFTimeInterval = CACurrentMediaTime()
    private var cycleStartTime: CFTimeInterval = CACurrentMediaTime()
    private var beatInterval: TimeInterval = 0.5
    private var rhythmInterval: TimeInterval = 0.5
    private var cycleDuration: TimeInterval = 2.0
    private var beatPulseActive = false
    private var rhythmPulseActive = false
    private var cycleActive = false
    private var currentBeatPulse = 0.0
    private var currentRhythmPulse = 0.0
    private var currentCycleProgress = 0.0

    var onUpdate: ((Double, Double, Double) -> Void)?

    func start() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        beatPulseActive = false
        rhythmPulseActive = false
        cycleActive = false
        currentBeatPulse = 0
        currentRhythmPulse = 0
        currentCycleProgress = 0
        onUpdate?(currentBeatPulse, currentRhythmPulse, currentCycleProgress)
    }

    func notifyBeat(interval: TimeInterval) {
        lastBeatTime = CACurrentMediaTime()
        beatInterval = max(interval, 0.001)
        beatPulseActive = true
        currentBeatPulse = 1.0
        onUpdate?(currentBeatPulse, currentRhythmPulse, currentCycleProgress)
    }

    func notifyRhythm(interval: TimeInterval) {
        lastRhythmTime = CACurrentMediaTime()
        rhythmInterval = max(interval, 0.001)
        rhythmPulseActive = true
        currentRhythmPulse = 1.0
        onUpdate?(currentBeatPulse, currentRhythmPulse, currentCycleProgress)
    }

    func notifyCycleStart(duration: TimeInterval) {
        cycleStartTime = CACurrentMediaTime()
        cycleDuration = max(duration, 0.001)
        cycleActive = true
        currentCycleProgress = 0
        onUpdate?(currentBeatPulse, currentRhythmPulse, currentCycleProgress)
    }

    @objc private func tick(_ displayLink: CADisplayLink) {
        guard beatPulseActive || rhythmPulseActive || cycleActive else { return }

        if beatPulseActive {
            currentBeatPulse = progressRemaining(
                from: lastBeatTime,
                duration: beatInterval,
                timestamp: displayLink.timestamp,
            )
            beatPulseActive = currentBeatPulse > 0
        }

        if rhythmPulseActive {
            currentRhythmPulse = progressRemaining(
                from: lastRhythmTime,
                duration: rhythmInterval,
                timestamp: displayLink.timestamp,
            )
            rhythmPulseActive = currentRhythmPulse > 0
        }

        if cycleActive {
            currentCycleProgress = progressElapsed(
                from: cycleStartTime,
                duration: cycleDuration,
                timestamp: displayLink.timestamp,
            )
            cycleActive = currentCycleProgress < 1
        }

        onUpdate?(currentBeatPulse, currentRhythmPulse, currentCycleProgress)
    }

    private func progressRemaining(from startTime: CFTimeInterval, duration: TimeInterval, timestamp: CFTimeInterval) -> Double {
        1.0 - progressElapsed(from: startTime, duration: duration, timestamp: timestamp)
    }

    private func progressElapsed(from startTime: CFTimeInterval, duration: TimeInterval, timestamp: CFTimeInterval) -> Double {
        let elapsed = timestamp - startTime
        return min(1.0, max(0.0, elapsed / duration))
    }
}
