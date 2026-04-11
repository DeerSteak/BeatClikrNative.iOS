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
    //MARK: Private variables
    private let vibration: VibrationService
    private let flashlight: FlashlightService
    private let audio: AudioPlayerService
    private let defaults: UserDefaultsService

    private var isLiveMode: Bool = false
    private var liveModeStarted: Bool = false
    private var isMuted: Bool = false
    private var useFlashlight: Bool = false
    private var useVibration: Bool = false
    private var song: Song

    private var isBeat: Bool = false

    //MARK: Published properties
    @Published var iconScale: CGFloat = MetronomeConstants.iconScaleMin
    @Published var isPlaying: Bool = false

    @Published var beatsPerMinute: Double = UserDefaultsService.instance.instantBpm {
        didSet {
            if clickerType == .instant {
                Song.instantSong.beatsPerMinute = beatsPerMinute
                defaults.instantBpm = beatsPerMinute
            }
            // Update tempo in real-time if playing
            if isPlaying {
                audio.updateTempo(bpm: beatsPerMinute, subdivisions: song.groove!.rawValue)
            }
        }
    }

    @Published var selectedGroove: Groove = UserDefaultsService.instance.instantGroove {
        didSet {
            if clickerType == .instant {
                Song.instantSong.groove = selectedGroove
                defaults.instantGroove = selectedGroove
            }
            // Update subdivisions in real-time if playing
            if isPlaying {
                audio.updateTempo(bpm: beatsPerMinute, subdivisions: selectedGroove.rawValue)
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

    @Published var clickerType: ClickerType = .instant {
        didSet {
            if !isPlaying {
                resetMetronome()
            }
        }
    }

    //MARK: Initializer
    init(
        vibration: VibrationService = .instance,
        flashlight: FlashlightService = .instance,
        audio: AudioPlayerService = .instance,
        defaults: UserDefaultsService = .instance
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
        clickerType = .instant
        isBeat = false

        // Set self as delegate for audio callbacks
        audio.delegate = self
    }

    //MARK: MetronomeAudioEngineDelegate
    func metronomeBeatFired(isBeat: Bool) {
        self.isBeat = isBeat

        if isBeat {
            // Reset scale to max instantly on beat
            iconScale = MetronomeConstants.iconScaleMax

            // Calculate duration for one full beat (in seconds)
            let beatDuration = 60.0 / (song.beatsPerMinute ?? 60)

            // Animate linearly to min over the beat duration
            withAnimation(.linear(duration: beatDuration)) {
                iconScale = MetronomeConstants.iconScaleMin
            }

            handleBeat()
        } else {
            handleRhythm()
        }
    }

    //MARK: Public functions
    func switchSong(_ song: Song) {
        self.song = song

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
        isMuted = defaults.muteMetronome
        useFlashlight = defaults.useFlashlight
        useVibration = defaults.useVibration
        
        if let bpm = song.beatsPerMinute, !bpm.isNaN {
            if bpm < MetronomeConstants.minBPM {
                song.beatsPerMinute = MetronomeConstants.minBPM
            }
            else if bpm > MetronomeConstants.maxBPM {
                song.beatsPerMinute = MetronomeConstants.maxBPM
            }
        }
        else {
            song.beatsPerMinute = MetronomeConstants.minBPM
        }

        if song.groove == nil {
            song.groove = .quarter
        }

        audio.setupAudioPlayer(beatName: beat.rawValue, rhythmName: rhythm.rawValue)
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
        setupMetronome()
        let bpm = song.beatsPerMinute ?? MetronomeConstants.minBPM
        let groove = song.groove?.rawValue ?? Groove.quarter.rawValue
        audio.startMetronome(bpm: bpm, subdivisions: groove)
        isPlaying = true
    }

    func stop() {
        audio.stopMetronome()
        flashlight.turnFlashlightOff()
        isPlaying = false
    }

    func resetMetronome() {
        let wasPlaying = isPlaying
        stop()

        if clickerType == .instant {
            beat = defaults.instantBeat
            rhythm = defaults.instantRhythm
        } else {
            beat = defaults.playlistBeat
            rhythm = defaults.playlistRhythm
        }
        setupMetronome()
        if wasPlaying {
            start()
        }
    }

    //MARK: Private helpers
    private func handleBeat() {
        if !isMuted && !liveModeStarted {
            // Audio is handled by the sequencer
        }
        if useVibration {
            vibration.vibrateBeat()
        }
        if useFlashlight {
            flashlight.turnFlashlightOn()
        }
    }

    private func handleRhythm() {
        if !isMuted && !liveModeStarted {
            // Audio is handled by the sequencer
        }
        if useVibration {
            vibration.vibrateRhythm()
        }
        if useFlashlight {
            flashlight.turnFlashlightOff()
        }
    }
}
