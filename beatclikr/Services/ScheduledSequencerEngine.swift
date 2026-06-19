//
//  ScheduledSequencerEngine.swift
//  beatclikr
//
//  Created by Ben Funk on 6/19/26.
//

import AVFoundation
import Foundation

@MainActor
protocol SequencerAudioEngineDelegate: AnyObject {
    func sequencerStepFired(step: Int, measure: Int, beat: Int)
}

class ScheduledSequencerEngine {
    private let engine = AVAudioEngine()
    private var playerNodes: [String: AVAudioPlayerNode] = [:] // instrumentID -> node
    private var audioFiles: [String: AVAudioFile] = [:]
    private var pattern: SequencePattern?
    private var tempo: Double = 120.0
    private var isPlaying = false
    private var currentStep = 0

    weak var delegate: SequencerAudioEngineDelegate?

    func start() throws {
        if !engine.isRunning {
            try engine.start()
        }
    }

    func stop() {
        engine.stop()
    }

    func loadSounds(instruments _: [FileConstants], from _: [SoundFile]) {
        // Create one AVAudioPlayerNode per instrument
        // Attach to engine mixer
        // Load AVAudioFile for each instrument
    }

    func startSequencer(pattern: SequencePattern, delegate: SequencerAudioEngineDelegate?) {
        self.pattern = pattern
        self.delegate = delegate
        currentStep = 0
        isPlaying = true

        // Schedule first loop iteration
        scheduleNextLoop()
    }

    func stopSequencer() {
        isPlaying = false
        // Stop all player nodes
    }

    func updatePattern(_ pattern: SequencePattern) {
        self.pattern = pattern
        // Pattern updates apply on next loop iteration
    }

    func updateTempo(_ bpm: Double) {
        tempo = bpm
        // Tempo changes apply on next scheduled buffer
    }

    private func scheduleNextLoop() {
        // Schedule all active instruments for each step in pattern
        // Use AVAudioTime for sample-accurate timing
        // Calculate step interval: 60.0 / (tempo * config.subdivisionsPerBeat)
        // Dispatch delegate callback to main thread for each step
    }
}
