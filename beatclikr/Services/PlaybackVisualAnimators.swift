//
//  PlaybackVisualAnimators.swift
//  beatclikr
//
//  Created by Ben Funk 7/27/26
//

import UIKit

final class MetronomeVisualAnimator: NSObject {
    private var displayLink: CADisplayLink?
    private var lastBeatTime: CFTimeInterval = CACurrentMediaTime()
    private var beatInterval: TimeInterval = 0.5
    private var isAnimating = false
    private var lastPlaybackTime: TimeInterval?
    private var lastMediaTime: CFTimeInterval?

    var onUpdate: ((CGFloat, Double) -> Void)?
    var playbackTime: (() -> TimeInterval?)?
    var reduceMotionEnabled: () -> Bool = { false }

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
        lastBeatTime = currentTime()
        beatInterval = max(interval, 0.001)
        let reduceMotion = reduceMotionEnabled()
        onUpdate?(
            reduceMotion ? MetronomeConstants.iconScaleMin : MetronomeConstants.iconScaleMax,
            reduceMotion ? 0 : 1,
        )
    }

    @objc private func tick(_ displayLink: CADisplayLink) {
        guard isAnimating else { return }
        guard !reduceMotionEnabled() else {
            onUpdate?(MetronomeConstants.iconScaleMin, 0)
            return
        }
        let elapsed = currentTime(fallback: displayLink.timestamp) - lastBeatTime
        let progress = AudioVisualPhase.elapsed(from: 0, to: elapsed, duration: beatInterval)
        let scale = MetronomeConstants.iconScaleMax
            + (MetronomeConstants.iconScaleMin - MetronomeConstants.iconScaleMax) * CGFloat(progress)
        onUpdate?(scale, 1.0 - progress)
    }

    private func currentTime(fallback: CFTimeInterval = CACurrentMediaTime()) -> CFTimeInterval {
        if let playbackTime = playbackTime?() {
            lastPlaybackTime = playbackTime
            lastMediaTime = fallback
            return playbackTime
        }
        if let lastPlaybackTime, let lastMediaTime {
            return lastPlaybackTime + fallback - lastMediaTime
        }
        return fallback
    }
}

final class PolyrhythmVisualAnimator: NSObject {
    private var displayLink: CADisplayLink?
    private var lastBeatTime: CFTimeInterval = CACurrentMediaTime()
    private var lastRhythmTime: CFTimeInterval = CACurrentMediaTime()
    private var cycleStartTime: CFTimeInterval = CACurrentMediaTime()
    private var beatInterval: TimeInterval = 0.5
    private var rhythmInterval: TimeInterval = 0.5
    private var cycleDuration: TimeInterval = 2
    private var beatPulseActive = false
    private var rhythmPulseActive = false
    private var cycleActive = false
    private var currentBeatPulse = 0.0
    private var currentRhythmPulse = 0.0
    private var currentCycleProgress = 0.0
    private var lastPlaybackTime: TimeInterval?
    private var lastMediaTime: CFTimeInterval?

    var onUpdate: ((Double, Double, Double) -> Void)?
    var playbackTime: (() -> TimeInterval?)?
    var reduceMotionEnabled: () -> Bool = { false }

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
        publish()
    }

    func notifyBeat(interval: TimeInterval) {
        lastBeatTime = currentTime()
        beatInterval = max(interval, 0.001)
        beatPulseActive = !reduceMotionEnabled()
        currentBeatPulse = beatPulseActive ? 1 : 0
        publish()
    }

    func notifyRhythm(interval: TimeInterval) {
        lastRhythmTime = currentTime()
        rhythmInterval = max(interval, 0.001)
        rhythmPulseActive = !reduceMotionEnabled()
        currentRhythmPulse = rhythmPulseActive ? 1 : 0
        publish()
    }

    func notifyCycleStart(duration: TimeInterval) {
        cycleStartTime = currentTime()
        cycleDuration = max(duration, 0.001)
        cycleActive = !reduceMotionEnabled()
        currentCycleProgress = 0
        publish()
    }

    @objc private func tick(_ displayLink: CADisplayLink) {
        guard !reduceMotionEnabled() else {
            beatPulseActive = false
            rhythmPulseActive = false
            cycleActive = false
            currentBeatPulse = 0
            currentRhythmPulse = 0
            currentCycleProgress = 0
            publish()
            return
        }
        guard beatPulseActive || rhythmPulseActive || cycleActive else { return }
        let timestamp = currentTime(fallback: displayLink.timestamp)
        if beatPulseActive {
            currentBeatPulse = AudioVisualPhase.remaining(
                from: lastBeatTime,
                to: timestamp,
                duration: beatInterval,
            )
            beatPulseActive = currentBeatPulse > 0
        }
        if rhythmPulseActive {
            currentRhythmPulse = AudioVisualPhase.remaining(
                from: lastRhythmTime,
                to: timestamp,
                duration: rhythmInterval,
            )
            rhythmPulseActive = currentRhythmPulse > 0
        }
        if cycleActive {
            currentCycleProgress = AudioVisualPhase.elapsed(
                from: cycleStartTime,
                to: timestamp,
                duration: cycleDuration,
            )
            cycleActive = currentCycleProgress < 1
        }
        publish()
    }

    private func publish() {
        onUpdate?(currentBeatPulse, currentRhythmPulse, currentCycleProgress)
    }

    private func currentTime(fallback: CFTimeInterval = CACurrentMediaTime()) -> CFTimeInterval {
        if let playbackTime = playbackTime?() {
            lastPlaybackTime = playbackTime
            lastMediaTime = fallback
            return playbackTime
        }
        if let lastPlaybackTime, let lastMediaTime {
            return lastPlaybackTime + fallback - lastMediaTime
        }
        return fallback
    }
}
