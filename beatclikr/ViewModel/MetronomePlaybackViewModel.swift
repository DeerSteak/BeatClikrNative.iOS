//
//  MetronomePlaybackViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Combine
import Foundation
import QuartzCore
import SwiftUI

@MainActor
class MetronomePlaybackViewModel: ObservableObject, MetronomeAudioEngineDelegate {
    // MARK: Private variables

    private let vibration: VibrationService
    private let flashlight: FlashlightService
    private let audio: AudioPlayerService
    private let settings: SettingsViewModel
    private var settingsCancellables: Set<AnyCancellable> = []
    private let visualAnimator = MetronomeVisualAnimator()

    private var isLiveMode: Bool = false
    private var liveModeStarted: Bool = false
    private var song: Song

    private var isBeat: Bool = false
    private var activeBpm: Double = 120.0
    private var applyingRamp: Bool = false
    private var applyingSettingsChange: Bool = false

    // MARK: Published properties

    @Published var iconScale: CGFloat = MetronomeConstants.iconScaleMin
    @Published var beatPulse: Double = 0
    @Published var isPlaying: Bool = false
    @Published var currentSongTitle: String? = nil

    @Published var beatsPerMinute: Double = UserDefaultsService.instance.metronomeBpm {
        didSet {
            if clickerType == .metronome, !applyingRamp, !applyingSettingsChange {
                settings.updateMetronomeBpm(beatsPerMinute)
            }
            if isPlaying, !applyingRamp {
                audio.updateTempo(bpm: beatsPerMinute, subdivisions: selectedGroove.subdivisions)
            }
        }
    }

    @Published var rampEnabled: Bool = UserDefaultsService.instance.rampEnabled {
        didSet {
            if clickerType == .metronome, !applyingSettingsChange {
                settings.updateRampEnabled(rampEnabled)
            }
            if isPlaying {
                audio.setRamp(enabled: rampEnabled && clickerType == .metronome, increment: rampIncrement, interval: rampInterval)
            }
        }
    }

    @Published var rampIncrement: Int = UserDefaultsService.instance.rampIncrement {
        didSet {
            if clickerType == .metronome, !applyingSettingsChange {
                settings.updateRampIncrement(rampIncrement)
            }
            if isPlaying {
                audio.setRamp(enabled: rampEnabled && clickerType == .metronome, increment: rampIncrement, interval: rampInterval)
            }
        }
    }

    @Published var rampInterval: Int = UserDefaultsService.instance.rampInterval {
        didSet {
            if clickerType == .metronome, !applyingSettingsChange {
                settings.updateRampInterval(rampInterval)
            }
            if isPlaying {
                audio.setRamp(enabled: rampEnabled && clickerType == .metronome, increment: rampIncrement, interval: rampInterval)
            }
        }
    }

    @Published var selectedGroove: Groove = UserDefaultsService.instance.metronomeGroove {
        didSet {
            if clickerType == .metronome, !applyingSettingsChange {
                settings.updateMetronomeGroove(selectedGroove)
            }
            if isPlaying {
                audio.startMetronome(bpm: beatsPerMinute, subdivisions: selectedGroove.subdivisions, accentPattern: computeAccentPattern())
            }
        }
    }

    @Published var beat: FileConstants = UserDefaultsService.instance.metronomeBeat {
        didSet {
            if !applyingSettingsChange {
                if clickerType == .metronome {
                    settings.updateMetronomeBeat(beat)
                } else {
                    settings.updatePlaylistBeat(beat)
                }
            }
            audio.setupMetronomeAudio(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
        }
    }

    @Published var rhythm: FileConstants = UserDefaultsService.instance.metronomeRhythm {
        didSet {
            if !applyingSettingsChange {
                if clickerType == .metronome {
                    settings.updateMetronomeRhythm(rhythm)
                } else {
                    settings.updatePlaylistRhythm(rhythm)
                }
            }
            audio.setupMetronomeAudio(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
        }
    }

    @Published var selectedBeatPattern: BeatPattern? = nil {
        didSet {
            if clickerType == .metronome, !applyingSettingsChange {
                settings.updateMetronomeBeatPattern(selectedBeatPattern)
            }
            if isPlaying {
                audio.startMetronome(bpm: beatsPerMinute, subdivisions: selectedGroove.subdivisions, accentPattern: computeAccentPattern())
            }
        }
    }

    @Published var clickerType: ClickerType = .metronome {
        didSet {
            if !isPlaying {
                resetMetronome()
            }
        }
    }

    // MARK: Initializer

    init(
        vibration: VibrationService = .instance,
        flashlight: FlashlightService = .instance,
        audio: AudioPlayerService = .instance,
        settings: SettingsViewModel = SettingsViewModel(),
    ) {
        self.vibration = vibration
        self.flashlight = flashlight
        self.audio = audio
        self.settings = settings

        song = Song.metronomeSong()
        song.groove = settings.metronomeGroove
        song.beatsPerMinute = settings.metronomeBpm
        beatsPerMinute = settings.metronomeBpm
        rampEnabled = settings.rampEnabled
        rampIncrement = settings.rampIncrement
        rampInterval = settings.rampInterval
        selectedGroove = settings.metronomeGroove
        beat = settings.metronomeBeat
        rhythm = settings.metronomeRhythm
        selectedBeatPattern = settings.metronomeBeatPattern.flatMap { BeatPattern(rawValue: $0) }
        clickerType = .metronome
        isBeat = false

        // Set self as delegate for audio callbacks
        audio.metronomeDelegate = self
        visualAnimator.onUpdate = { [weak self] scale, pulse in
            self?.iconScale = scale
            self?.beatPulse = pulse
        }
        observeSettings()
    }

    // MARK: MetronomeAudioEngineDelegate

    func metronomeBeatFired(isBeat: Bool, beatInterval: TimeInterval) {
        self.isBeat = isBeat

        if isBeat {
            visualAnimator.notifyBeat(interval: beatInterval)
            handleBeat()
        } else {
            handleRhythm()
        }
    }

    func metronomeRampStepped(newBpm: Double) {
        applyingRamp = true
        beatsPerMinute = newBpm
        applyingRamp = false
    }

    // MARK: Public functions

    func switchSong(_ song: Song) {
        self.song = song
        currentSongTitle = song.title

        // Reload beat/rhythm from defaults in case they changed in settings
        if clickerType == .metronome {
            beat = settings.metronomeBeat
            rhythm = settings.metronomeRhythm
        } else {
            beat = settings.playlistBeat
            rhythm = settings.playlistRhythm
        }

        setupMetronome()
    }

    func setupMetronome() {
        if let bpm = song.beatsPerMinute, !bpm.isNaN {
            if bpm < MetronomeConstants.minBPM {
                song.beatsPerMinute = MetronomeConstants.minBPM
            } else if bpm > MetronomeConstants.maxBPM {
                song.beatsPerMinute = MetronomeConstants.maxBPM
            }
        } else {
            song.beatsPerMinute = MetronomeConstants.minBPM
        }

        if song.groove == nil {
            song.groove = .quarter
        }

        audio.setupMetronomeAudio(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
    }

    func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            start()
        } else {
            stop()
        }
    }

    func start() {
        if clickerType == .metronome {
            song = Song.metronomeSong()
            song.beatsPerMinute = beatsPerMinute
            song.groove = selectedGroove
            currentSongTitle = nil
        }
        setupMetronome()
        let bpm = song.beatsPerMinute ?? beatsPerMinute
        activeBpm = bpm
        let groove = song.groove ?? selectedGroove
        audio.setRamp(enabled: rampEnabled && clickerType == .metronome, increment: rampIncrement, interval: rampInterval)
        audio.startMetronome(bpm: bpm, subdivisions: groove.subdivisions, accentPattern: computeAccentPattern())
        visualAnimator.start()
        isPlaying = true
    }

    func stop() {
        audio.stopMetronome()
        visualAnimator.stop()
        flashlight.turnFlashlightOff()
        isPlaying = false
        if rampEnabled, clickerType == .metronome {
            beatsPerMinute = activeBpm
        }
    }

    func resetMetronome() {
        let wasPlaying = isPlaying
        stop()

        if clickerType == .metronome {
            song = Song.metronomeSong()
            song.groove = selectedGroove
            song.beatsPerMinute = beatsPerMinute
            beat = settings.metronomeBeat
            rhythm = settings.metronomeRhythm
            selectedBeatPattern = settings.metronomeBeatPattern.flatMap { BeatPattern(rawValue: $0) }
        } else {
            beat = settings.playlistBeat
            rhythm = settings.playlistRhythm
        }
        setupMetronome()
        if wasPlaying {
            start()
        }
    }

    // MARK: Private helpers

    private func computeAccentPattern() -> [Bool]? {
        let groove = clickerType == .metronome ? selectedGroove : (song.groove ?? .quarter)
        guard groove.isOddMeter else { return nil }
        if clickerType == .metronome {
            return (selectedBeatPattern ?? .sevenEightA).accentArray
        } else {
            return (BeatPattern(rawValue: song.beatPattern ?? "") ?? .sevenEightA).accentArray
        }
    }

    private func handleBeat() {
        if settings.useVibration {
            vibration.vibrateBeat()
        }
        if settings.useFlashlight {
            flashlight.turnFlashlightOn()
        }
    }

    private func handleRhythm() {
        if settings.useVibration {
            vibration.vibrateRhythm()
        }
        if settings.useFlashlight {
            flashlight.turnFlashlightOff()
        }
    }

    private func observeSettings() {
        settings.$metronomeBpm
            .dropFirst()
            .sink { [weak self] bpm in
                guard let self, clickerType == .metronome, beatsPerMinute != bpm else { return }
                applySettingsChange { self.beatsPerMinute = bpm }
            }
            .store(in: &settingsCancellables)

        settings.$metronomeGroove
            .dropFirst()
            .sink { [weak self] groove in
                guard let self, clickerType == .metronome, selectedGroove != groove else { return }
                applySettingsChange { self.selectedGroove = groove }
            }
            .store(in: &settingsCancellables)

        settings.$metronomeBeat
            .dropFirst()
            .sink { [weak self] beat in
                guard let self, clickerType == .metronome, self.beat != beat else { return }
                applySettingsChange { self.beat = beat }
            }
            .store(in: &settingsCancellables)

        settings.$metronomeRhythm
            .dropFirst()
            .sink { [weak self] rhythm in
                guard let self, clickerType == .metronome, self.rhythm != rhythm else { return }
                applySettingsChange { self.rhythm = rhythm }
            }
            .store(in: &settingsCancellables)

        settings.$soundBank
            .dropFirst()
            .sink { [weak self] bank in
                guard let self else { return }
                audio.setSoundBank(bank)
                audio.setupMetronomeAudio(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
            }
            .store(in: &settingsCancellables)

        settings.$metronomeBeatPattern
            .dropFirst()
            .sink { [weak self] rawValue in
                guard let self, clickerType == .metronome else { return }
                let beatPattern = rawValue.flatMap { BeatPattern(rawValue: $0) }
                guard selectedBeatPattern != beatPattern else { return }
                applySettingsChange { self.selectedBeatPattern = beatPattern }
            }
            .store(in: &settingsCancellables)

        settings.$rampEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                guard let self, rampEnabled != enabled else { return }
                applySettingsChange { self.rampEnabled = enabled }
            }
            .store(in: &settingsCancellables)

        settings.$rampIncrement
            .dropFirst()
            .sink { [weak self] increment in
                guard let self, rampIncrement != increment else { return }
                applySettingsChange { self.rampIncrement = increment }
            }
            .store(in: &settingsCancellables)

        settings.$rampInterval
            .dropFirst()
            .sink { [weak self] interval in
                guard let self, rampInterval != interval else { return }
                applySettingsChange { self.rampInterval = interval }
            }
            .store(in: &settingsCancellables)

        settings.$playlistBeat
            .dropFirst()
            .sink { [weak self] beat in
                guard let self, clickerType != .metronome, self.beat != beat else { return }
                applySettingsChange { self.beat = beat }
            }
            .store(in: &settingsCancellables)

        settings.$playlistRhythm
            .dropFirst()
            .sink { [weak self] rhythm in
                guard let self, clickerType != .metronome, self.rhythm != rhythm else { return }
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

private final class MetronomeVisualAnimator: NSObject {
    private var displayLink: CADisplayLink?
    private var lastBeatTime: CFTimeInterval = CACurrentMediaTime()
    private var beatInterval: TimeInterval = 0.5
    private var isAnimating = false

    var onUpdate: ((CGFloat, Double) -> Void)?

    func start() {
        guard displayLink == nil else {
            isAnimating = true
            return
        }
        isAnimating = true
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        isAnimating = false
        lastBeatTime = CACurrentMediaTime()
        onUpdate?(MetronomeConstants.iconScaleMin, 0)
    }

    func notifyBeat(interval: TimeInterval) {
        lastBeatTime = CACurrentMediaTime()
        beatInterval = max(interval, 0.001)
        onUpdate?(MetronomeConstants.iconScaleMax, 1.0)
    }

    @objc private func tick(_ displayLink: CADisplayLink) {
        guard isAnimating else { return }
        let elapsed = displayLink.timestamp - lastBeatTime
        let progress = min(1.0, max(0.0, elapsed / beatInterval))
        let scale = lerp(
            from: MetronomeConstants.iconScaleMax,
            to: MetronomeConstants.iconScaleMin,
            progress: progress,
        )
        onUpdate?(scale, 1.0 - progress)
    }

    private func lerp(from: CGFloat, to: CGFloat, progress: Double) -> CGFloat {
        from + (to - from) * CGFloat(progress)
    }
}
