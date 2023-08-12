//
//  MetronomeService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation

class MetronomeService : MetronomeTimerDelegate {
   
    static var instance = MetronomeService()
    
    private var timer = MetronomeTimer.instance
    
    private var vibration = VibrationService.instance
    private var flashlight = FlashlightService.instance
    private var audio = AudioPlayerService.instance
    private var defaults = UserDefaultsService.instance
        
    private var subdivisions: Int = 1
    private var subdivisionMilliseconds: Double = 0
    
    private var timerEventCounter = 1
    private var beatsPlayed = 0
    private var isLiveMode = false
    private var liveModeStarted = false
    private var isMuted = false
    private var useFlashlight = false
    private var useVibration = false
    
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
        isMuted = defaults.getMuteMetronome()
        useFlashlight = defaults.getUseFlashlight()
        useVibration = defaults.getUseVibration()
        
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
