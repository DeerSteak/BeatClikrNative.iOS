//
//  MetronomeTimer.swift
//  beatclikr
//
//  Created by Ben Funk on 8/12/23.
//

import Foundation

protocol MetronomeTimerDelegate {
    func metronomeTimerFired()
}

class MetronomeTimer {    
    static var instance = MetronomeTimer(bpm: 60, subdivisions: 2)
    
    // MARK: Public properties
    var delegate: MetronomeTimerDelegate?
    
    var beatsPerMinute: Double {
        didSet {
            updateTempo()
        }
    }
    
    var subdivisions: Int {
        didSet {
            updateTempo()
        }
    }
    
    // MARK: - Private Properties
    
    private var timer: DispatchSourceTimer!
    
    // Grand Central Dispatch runs the timer.
    // Concept came from here: https://www.raywenderlich.com/5370-grand-central-dispatch-tutorial-for-swift-4-part-1-2
    private lazy var timerQueue = DispatchQueue.global(qos: .userInteractive)
    
    private var paused: Bool
    private var previousSubdivisionTime: CFAbsoluteTime
    
    private var subdivisionCheckInterval: Double {
        return getSubdivisionDuration() / 50 //check time many times per subdivision, higher the number the more accurate, but this should be plenty accurate.
    }
    
    private var elapsedTime: Double {
        return CFAbsoluteTimeGetCurrent() - previousSubdivisionTime
    }
    
    //MARK: Init/deinit
    
    init(bpm: Double, subdivisions: Int) {
        self.beatsPerMinute = bpm
        self.subdivisions = subdivisions
        self.paused = true
        self.previousSubdivisionTime = CFAbsoluteTimeGetCurrent()
        self.timer = createNewTimer()
    }
    
    deinit {
        cancelTimer()
    }
    
    // MARK: Public functions
    
    func start() {
        if paused {
            paused = false
            previousSubdivisionTime = CFAbsoluteTimeGetCurrent() //reset time since last to now, so the resume works as expected
            timer.resume()
        }
    }
    
    func stop() {
        if !paused {
            paused = true
            timer.suspend()
        }
    }
    
    // MARK: Private methods
    private func getTimerTolerance() -> DispatchTimeInterval {
        return DispatchTimeInterval.milliseconds(Int(subdivisionCheckInterval * 0.1 * 1000.0)) //10% tolerance per Apple's recommendation, expressed in milliseconds
    }
    
    //number of seconds per subdivision
    private func getSubdivisionDuration() -> Double {
        return 60 / (beatsPerMinute * Double(subdivisions))
    }
    
    //The amount of time until the next subdivision
    private func getTimeToNextSubdivision() -> Double {
        if paused {
            return getSubdivisionDuration()
        } else {
            return abs(elapsedTime - getSubdivisionDuration())
        }
    }
    
    private func createNewTimer() -> DispatchSourceTimer {
        let dst = DispatchSource.makeTimerSource(queue: timerQueue)
        let deadline = DispatchTime.now() + subdivisionCheckInterval
        
        dst.setEventHandler {
            self.checkTimeToPlay()
        }
        
        dst.schedule(deadline: deadline, repeating: subdivisionCheckInterval, leeway: getTimerTolerance())
        dst.activate()
        
        //don't start if paused
        if paused {
            dst.suspend()
        }
        
        return dst
    }
    
    private func cancelTimer() {
        timer.setEventHandler(handler: nil)
        timer.cancel()
        if paused {
            timer.resume() // If the timer is suspended, calling cancel without resuming triggers a crash. See here for more info: https://forums.developer.apple.com/thread/15902
        }
    }
    
    private func updateTempo() {
        cancelTimer()
        timer = createNewTimer()
    }
    
    private func checkTimeToPlay() {
        // If past or extremely close to correct duration, play. It might float by a few milliseconds but it will not drift out of sync over time.
        if (elapsedTime > getSubdivisionDuration()) || (getTimeToNextSubdivision() < 0.005) {
            timerElapsed()
        }
    }
    
    private func timerElapsed() {
        previousSubdivisionTime = CFAbsoluteTimeGetCurrent()
        DispatchQueue.main.sync {
            delegate?.metronomeTimerFired() // Have the delegate respond accordingly
        }
    }
}
