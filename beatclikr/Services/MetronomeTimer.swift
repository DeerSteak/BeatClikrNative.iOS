//
//  MetronomeTimer.swift
//  beatclikr
//
//  Created by Ben Funk on 8/12/23.
//

import Foundation

@MainActor
protocol MetronomeTimerDelegate: AnyObject {
    func metronomeTimerFired()
}

@MainActor
class MetronomeTimer {
    static let instance = MetronomeTimer(bpm: 60, subdivisions: 2)

    // MARK: Public properties
    weak var delegate: (any MetronomeTimerDelegate)?
    
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

    private var timer: Timer?
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
    }

    // MARK: Public functions
    
    func start() {
        if paused {
            paused = false
            previousSubdivisionTime = CFAbsoluteTimeGetCurrent()
            startTimer()
        }
    }

    func stop() {
        if !paused {
            paused = true
            timer?.invalidate()
            timer = nil
        }
    }
    
    // MARK: Private methods
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
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: subdivisionCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkTimeToPlay()
            }
        }
        // Use common run loop mode to ensure timer fires even during UI interactions
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func updateTempo() {
        if !paused {
            startTimer()
        }
    }
    
    private func checkTimeToPlay() {
        // If past or extremely close to correct duration, play. It might float by a few milliseconds but it will not drift out of sync over time.
        if (elapsedTime > getSubdivisionDuration()) || (getTimeToNextSubdivision() < 0.005) {
            timerElapsed()
        }
    }
    
    private func timerElapsed() {
        previousSubdivisionTime = CFAbsoluteTimeGetCurrent()
        delegate?.metronomeTimerFired()
    }
}

