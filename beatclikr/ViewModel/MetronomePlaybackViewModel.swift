//
//  MetronomePlaybackViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation
import SwiftUI

@MainActor
class MetronomePlaybackViewModel: ObservableObject, MetronomeAudioEngineDelegate {
    // MARK: Private variables

    private let vibration: VibrationService
    private let flashlight: FlashlightService
    private let audio: AudioPlayerService
    private let defaults: UserDefaultsService

    private var isLiveMode: Bool = false
    private var liveModeStarted: Bool = false
    private var song: Song

    private var isBeat: Bool = false
    private var activeBpm: Double = 120.0
    private var rampBeatCount: Int = -1
    private var applyingRamp: Bool = false

    // MARK: Published properties

    @Published var iconScale: CGFloat = MetronomeConstants.iconScaleMin
    @Published var beatPulse: Double = 0
    @Published var isPlaying: Bool = false
    @Published var currentSongTitle: String? = nil

    @Published var beatsPerMinute: Double = UserDefaultsService.instance.instantBpm {
        didSet {
            if clickerType == .instant, !applyingRamp {
                defaults.instantBpm = beatsPerMinute
            }
            if isPlaying, !applyingRamp {
                audio.startMetronome(bpm: beatsPerMinute, subdivisions: selectedGroove.subdivisions, accentPattern: computeAccentPattern())
            }
        }
    }

    @Published var rampEnabled: Bool = UserDefaultsService.instance.rampEnabled {
        didSet {
            if clickerType == .instant {
                defaults.rampEnabled = rampEnabled
            }
        }
    }

    @Published var rampIncrement: Int = UserDefaultsService.instance.rampIncrement {
        didSet {
            if clickerType == .instant {
                defaults.rampIncrement = rampIncrement
            }
        }
    }

    @Published var rampInterval: Int = UserDefaultsService.instance.rampInterval {
        didSet {
            if clickerType == .instant {
                defaults.rampInterval = rampInterval
            }
        }
    }

    @Published var selectedGroove: Groove = UserDefaultsService.instance.instantGroove {
        didSet {
            if clickerType == .instant {
                defaults.instantGroove = selectedGroove
            }
            if isPlaying {
                audio.startMetronome(bpm: beatsPerMinute, subdivisions: selectedGroove.subdivisions, accentPattern: computeAccentPattern())
            }
        }
    }

    @Published var beat: FileConstants = UserDefaultsService.instance.instantBeat {
        didSet {
            if clickerType == .instant {
                defaults.instantBeat = beat
            } else {
                defaults.playlistBeat = beat
            }
            audio.setupAudioPlayer(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
        }
    }

    @Published var rhythm: FileConstants = UserDefaultsService.instance.instantRhythm {
        didSet {
            if clickerType == .instant {
                defaults.instantRhythm = rhythm
            } else {
                defaults.playlistRhythm = rhythm
            }
            audio.setupAudioPlayer(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
        }
    }

    @Published var selectedBeatPattern: BeatPattern? = nil {
        didSet {
            if clickerType == .instant {
                defaults.instantBeatPattern = selectedBeatPattern?.rawValue
            }
            if isPlaying {
                audio.startMetronome(bpm: beatsPerMinute, subdivisions: selectedGroove.subdivisions, accentPattern: computeAccentPattern())
            }
        }
    }

    @Published var clickerType: ClickerType = .instant {
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
        defaults: UserDefaultsService = .instance,
    ) {
        self.vibration = vibration
        self.flashlight = flashlight
        self.audio = audio
        self.defaults = defaults

        song = Song.instantSong
        song.groove = defaults.instantGroove
        song.beatsPerMinute = defaults.instantBpm
        beat = defaults.instantBeat
        rhythm = defaults.instantRhythm
        selectedBeatPattern = defaults.instantBeatPattern.flatMap { BeatPattern(rawValue: $0) }
        clickerType = .instant
        isBeat = false

        // Set self as delegate for audio callbacks
        audio.delegate = self
    }

    // MARK: MetronomeAudioEngineDelegate

    func metronomeBeatFired(isBeat: Bool, beatInterval: TimeInterval) {
        self.isBeat = isBeat

        if isBeat {
            // Snap to max instantly with no animation
            withAnimation(.none) {
                iconScale = MetronomeConstants.iconScaleMax
                beatPulse = 1.0
            }

            // Fade out over the exact interval to the next beat, matching each rhythmic group
            Task { @MainActor in
                withAnimation(.linear(duration: beatInterval)) {
                    self.iconScale = MetronomeConstants.iconScaleMin
                    self.beatPulse = 0.0
                }
            }

            handleBeat()
        } else {
            handleRhythm()
        }
    }

    // MARK: Public functions

    func switchSong(_ song: Song) {
        self.song = song
        currentSongTitle = song.title

        // Reload beat/rhythm from defaults in case they changed in settings
        if clickerType == .instant {
            beat = defaults.instantBeat
            rhythm = defaults.instantRhythm
        } else {
            beat = defaults.playlistBeat
            rhythm = defaults.playlistRhythm
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

        audio.setupAudioPlayer(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
    }

    func onAppear() {
        clickerType = .instant
        UIApplication.shared.isIdleTimerDisabled = defaults.keepAwake
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
        if clickerType == .instant {
            song = Song.instantSong
            song.beatsPerMinute = beatsPerMinute
            song.groove = selectedGroove
            currentSongTitle = nil
        }
        setupMetronome()
        let bpm = song.beatsPerMinute ?? beatsPerMinute
        activeBpm = bpm
        let groove = song.groove ?? selectedGroove
        audio.startMetronome(bpm: bpm, subdivisions: groove.subdivisions, accentPattern: computeAccentPattern())
        isPlaying = true
    }

    func stop() {
        rampBeatCount = -1
        audio.stopMetronome()
        flashlight.turnFlashlightOff()
        isPlaying = false
        if rampEnabled, clickerType == .instant {
            beatsPerMinute = activeBpm
        }
    }

    func resetMetronome() {
        let wasPlaying = isPlaying
        stop()

        if clickerType == .instant {
            song = Song.instantSong
            song.groove = selectedGroove
            song.beatsPerMinute = beatsPerMinute
            beat = defaults.instantBeat
            rhythm = defaults.instantRhythm
            selectedBeatPattern = defaults.instantBeatPattern.flatMap { BeatPattern(rawValue: $0) }
        } else {
            beat = defaults.playlistBeat
            rhythm = defaults.playlistRhythm
        }
        setupMetronome()
        if wasPlaying {
            start()
        }
    }

    // MARK: Private helpers

    private func computeAccentPattern() -> [Bool]? {
        let groove = clickerType == .instant ? selectedGroove : (song.groove ?? .quarter)
        guard groove.isOddMeter else { return nil }
        if clickerType == .instant {
            return (selectedBeatPattern ?? .sevenEightA).accentArray
        } else {
            return (BeatPattern(rawValue: song.beatPattern ?? "") ?? .sevenEightA).accentArray
        }
    }

    private func handleBeat() {
        if defaults.useVibration {
            vibration.vibrateBeat()
        }
        if defaults.useFlashlight {
            flashlight.turnFlashlightOn()
        }
        guard rampEnabled, clickerType == .instant else { return }
        rampBeatCount += 1
        if rampBeatCount % rampInterval == 0, rampBeatCount > 0 {
            let newBpm = min(beatsPerMinute + Double(rampIncrement), MetronomeConstants.maxBPM)
            guard newBpm != beatsPerMinute else { return }
            applyingRamp = true
            beatsPerMinute = newBpm
            applyingRamp = false
            let subdivisions = selectedGroove.subdivisions
            Task { @MainActor in
                self.audio.updateTempo(bpm: newBpm, subdivisions: subdivisions)
            }
        }
    }

    private func handleRhythm() {
        if defaults.useVibration {
            vibration.vibrateRhythm()
        }
        if defaults.useFlashlight {
            flashlight.turnFlashlightOff()
        }
    }
}
