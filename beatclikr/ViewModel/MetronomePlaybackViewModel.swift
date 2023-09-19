//
//  MetronomePlaybackViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation
import SwiftUI

class MetronomePlaybackViewModel: ObservableObject, MetronomeTimerDelegate {
    
    //MARK: Private variables
    private var timer: MetronomeTimer = MetronomeTimer.instance
    private let vibration: VibrationService = VibrationService.instance
    private let flashlight: FlashlightService = FlashlightService.instance
    private let audio: AudioPlayerService = AudioPlayerService.instance
    private let defaults: UserDefaultsService = UserDefaultsService.instance
    private var subdivisions: Int = 1
    private var subdivisionMilliseconds: Double = 0
    private var timerEventCounter: Int = 1
    private var beatsPlayed: Int = 0
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
        }
    }
    
    @Published var selectedGroove: Groove = UserDefaultsService.instance.instantGroove {
        didSet {
            if clickerType == .instant {
                Song.instantSong.groove = selectedGroove
                defaults.instantGroove = selectedGroove
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
        }
    }
    
    @Published var rhythm: FileConstants = UserDefaultsService.instance.instantRhythm {
        didSet {
            if clickerType == .instant {
                defaults.instantRhythm = rhythm
            } else {
                defaults.playlistRhythm = rhythm
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

    //MARK: Initializer
    init() {
        song = Song.instantSong
        song.groove = defaults.instantGroove
        song.beatsPerMinute = defaults.instantBpm
        beat = defaults.instantBeat
        rhythm = defaults.instantRhythm
        clickerType = .instant
        isBeat = false
    }
    
    //MARK: Delegate handler
    func metronomeTimerFired() {
        if timerEventCounter == 1 {
            playBeat()
        }
        else {
            playRhythm()
        }
        timerEventCounter += 1
        if timerEventCounter > subdivisions {
            timerEventCounter = 1
        }
    }
    
    //MARK: Public functions
    func switchSong(song: Song) {
        self.song = song
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
        timer.beatsPerMinute = song.beatsPerMinute
        subdivisions = song.groove.rawValue
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
        timer.stop()
        timerEventCounter = 1
        beatsPlayed = 0
        timer.delegate = self
        timer.subdivisions = subdivisions
        timer.start()
        isPlaying = true
    }
    
    func stop() {
        timer.stop()
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
    private func playBeat() {
        isBeat = true
        if !isMuted && !liveModeStarted {
            audio.playBeat()
        }
        if useVibration {
            vibration.vibrateBeat()
        }
        if useFlashlight {
            flashlight.turnFlashlightOn()
        }
    }
    
    private func playRhythm() {
        isBeat = false
        if !isMuted && !liveModeStarted {
            audio.playRhythm()
        }
        if useVibration {
            vibration.vibrateRhythm()
        }
        if useFlashlight {
            flashlight.turnFlashlightOff()
        }
    }
}
