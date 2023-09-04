//
//  MetronomeService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation

class MetronomeService : MetronomeTimerDelegate, ObservableObject {
    
    static var instance: MetronomeService = MetronomeService()
    
    private var timer: MetronomeTimer = MetronomeTimer.instance
    
    private var vibration: VibrationService = VibrationService.instance
    private var flashlight: FlashlightService = FlashlightService.instance
    private var audio: AudioPlayerService = AudioPlayerService.instance
    private var defaults: UserDefaultsService = UserDefaultsService.instance
    
    private var subdivisions: Int = 1
    private var subdivisionMilliseconds: Double = 0
    
    private var timerEventCounter: Int = 1
    private var beatsPlayed: Int = 0
    private var isLiveMode: Bool = false
    private var liveModeStarted: Bool = false
    private var isMuted: Bool = false
    private var useFlashlight: Bool = false
    private var useVibration: Bool = false
    
    @Published var isBeat: Bool = false
    
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
    func setup(beatName: String, rhythmName: String, song: Song) {
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
        audio.setupAudioPlayer(beatName: beatName, rhythmName: rhythmName)
    }
    
    func start() {
        timerEventCounter = 1
        beatsPlayed = 0
        timer.delegate = self
        timer.subdivisions = subdivisions
        timer.start()
    }
    
    func stop() {
        flashlight.turnFlashlightOff()
        timer.stop()
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
