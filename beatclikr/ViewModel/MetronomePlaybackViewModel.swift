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

    private var isBeat: Bool = false {
        didSet {
            imageName = isBeat ? ImageConstants.beat : ImageConstants.rhythm
        }
    }

    //MARK: Published properties
    @Published var imageName: String = ImageConstants.rhythm
    @Published var isPlaying: Bool = false

    @Published var beatsPerMinute: Double = UserDefaultsService.instance.instantBpm {
        didSet {
            if clickerType == .instant {
                Song.instantSong.beatsPerMinute = beatsPerMinute
                defaults.instantBpm = beatsPerMinute
            }
            // Update tempo in real-time if playing
            if isPlaying {
                audio.updateTempo(bpm: beatsPerMinute, subdivisions: song.groove.rawValue)
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

        if song.beatsPerMinute < 30 {
            song.beatsPerMinute = 30
        }
        else if song.beatsPerMinute > 240 {
            song.beatsPerMinute = 240
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
        audio.startMetronome(bpm: song.beatsPerMinute, subdivisions: song.groove.rawValue)
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
