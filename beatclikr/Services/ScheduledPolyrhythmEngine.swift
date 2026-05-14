//
//  ScheduledPolyrhythmEngine.swift
//  beatclikr
//
//  Created by Ben Funk on 5/11/26.
//

import AVFoundation
import Foundation

/// Sample-accurate polyrhythm engine using two independent AVAudioPlayerNode tracks.
///
/// Beat and rhythm run as completely separate scheduling loops so they can fire at the
/// same sample time without any buffer-mixing code; AVAudioEngine handles the mix.
/// Delegate notifications are scheduled from the same sample timeline as playback
/// instead of using buffer completion as a proxy for beat onset.
///
/// For M against N:
///   - Beat track fires every quarter note (60/bpm seconds)
///   - Rhythm track fires every cycle/M seconds  (N*60 / (bpm*M) seconds)
///   - Both tracks start at the same firstBeatDelay origin
@MainActor
class ScheduledPolyrhythmEngine: PolyrhythmAudioEngine {
    private let engine = AVAudioEngine()
    private let beatNode = AVAudioPlayerNode()
    private let rhythmNode = AVAudioPlayerNode()

    private var beatBuffer: AVAudioPCMBuffer?
    private var rhythmBuffer: AVAudioPCMBuffer?

    // Beat track state
    private let scheduleAheadCount = 4
    private var beatScheduledCount = 0
    private var beatNextSampleTime: AVAudioFramePosition = 0
    private var currentBeatIndex = 0
    private var samplesPerBeat: Double = 0
    private var beatCount = 1 // against

    // Rhythm track state
    private var rhythmScheduledCount = 0
    private var rhythmNextSampleTime: AVAudioFramePosition = 0
    private var currentRhythmIndex = 0
    private var samplesPerRhythm: Double = 0
    private var rhythmCount = 1 // beats

    // Incremented on every start/stop so stale callbacks self-discard
    private var sessionID = 0
    private var eventStartTime: DispatchTime = .now()
    private var isPlaying = false

    private weak var delegate: PolyrhythmAudioEngineDelegate?

    // MARK: - PolyrhythmAudioEngine

    func loadSounds(beatName: String, rhythmName: String, from sounds: [SoundFile]) {
        if let file = sounds.first(where: { $0.displayName == beatName })?.audioFile {
            beatBuffer = readBuffer(from: file)
        }
        if let file = sounds.first(where: { $0.displayName == rhythmName })?.audioFile {
            rhythmBuffer = readBuffer(from: file)
        }
    }

    func startPolyrhythm(bpm: Double, beats: Int, against: Int, delegate: PolyrhythmAudioEngineDelegate) {
        guard bpm > 0, beats >= 1, against >= 1 else { return }

        sessionID += 1
        beatNode.stop()
        rhythmNode.stop()
        eventStartTime = .now()
        beatNode.play()
        rhythmNode.play()

        self.delegate = delegate
        beatCount = against
        rhythmCount = beats
        isPlaying = true

        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        samplesPerBeat = sampleRate * 60.0 / bpm
        samplesPerRhythm = sampleRate * Double(against) * 60.0 / (bpm * Double(beats))

        let origin = AVAudioFramePosition(sampleRate * MetronomeConstants.firstBeatDelay)
        beatNextSampleTime = origin
        rhythmNextSampleTime = origin
        currentBeatIndex = 0
        currentRhythmIndex = 0
        beatScheduledCount = 0
        rhythmScheduledCount = 0

        scheduleBeatBuffers()
        scheduleRhythmBuffers()
    }

    func stopPolyrhythm() {
        sessionID += 1
        isPlaying = false
        beatNode.stop()
        rhythmNode.stop()
        beatScheduledCount = 0
        rhythmScheduledCount = 0
    }

    func start() throws {
        engine.attach(beatNode)
        engine.attach(rhythmNode)
        engine.connect(beatNode, to: engine.mainMixerNode, format: nil)
        engine.connect(rhythmNode, to: engine.mainMixerNode, format: nil)
        try engine.start()
    }

    func stop() {
        beatNode.stop()
        rhythmNode.stop()
        engine.stop()
    }

    // MARK: - Private

    private func readBuffer(from file: AVAudioFile) -> AVAudioPCMBuffer? {
        file.framePosition = 0
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length),
        ) else { return nil }
        try? file.read(into: buffer)
        return buffer
    }

    private func scheduleBeatBuffers() {
        guard isPlaying, let buffer = beatBuffer else { return }

        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        let capturedSession = sessionID
        let muted = UserDefaultsService.instance.muteMetronome
        beatNode.volume = muted ? 0 : 1

        while beatScheduledCount < scheduleAheadCount {
            let capturedIndex = currentBeatIndex
            let scheduledSampleTime = beatNextSampleTime
            let when = AVAudioTime(sampleTime: scheduledSampleTime, atRate: sampleRate)

            scheduleDelegateEvent(
                beatFired: true,
                rhythmFired: false,
                beatIndex: capturedIndex,
                rhythmIndex: 0,
                sampleTime: scheduledSampleTime,
                sampleRate: sampleRate,
                sessionID: capturedSession,
            )

            beatNode.scheduleBuffer(buffer, at: when, options: [], completionCallbackType: .dataConsumed) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self, self.sessionID == capturedSession else { return }
                    self.beatScheduledCount -= 1
                    self.scheduleBeatBuffers()
                }
            }

            beatNextSampleTime += AVAudioFramePosition(samplesPerBeat)
            currentBeatIndex = (currentBeatIndex + 1) % beatCount
            beatScheduledCount += 1
        }
    }

    private func scheduleRhythmBuffers() {
        guard isPlaying, let buffer = rhythmBuffer else { return }

        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        let capturedSession = sessionID
        let muted = UserDefaultsService.instance.muteMetronome
        rhythmNode.volume = muted ? 0 : 1

        while rhythmScheduledCount < scheduleAheadCount {
            let capturedIndex = currentRhythmIndex
            let scheduledSampleTime = rhythmNextSampleTime
            let when = AVAudioTime(sampleTime: scheduledSampleTime, atRate: sampleRate)

            scheduleDelegateEvent(
                beatFired: false,
                rhythmFired: true,
                beatIndex: 0,
                rhythmIndex: capturedIndex,
                sampleTime: scheduledSampleTime,
                sampleRate: sampleRate,
                sessionID: capturedSession,
            )

            rhythmNode.scheduleBuffer(buffer, at: when, options: [], completionCallbackType: .dataConsumed) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self, self.sessionID == capturedSession else { return }
                    self.rhythmScheduledCount -= 1
                    self.scheduleRhythmBuffers()
                }
            }

            rhythmNextSampleTime += AVAudioFramePosition(samplesPerRhythm)
            currentRhythmIndex = (currentRhythmIndex + 1) % rhythmCount
            rhythmScheduledCount += 1
        }
    }

    private func scheduleDelegateEvent(
        beatFired: Bool,
        rhythmFired: Bool,
        beatIndex: Int,
        rhythmIndex: Int,
        sampleTime: AVAudioFramePosition,
        sampleRate: Double,
        sessionID capturedSession: Int,
    ) {
        let secondsFromStart = Double(sampleTime) / sampleRate
        let nanoseconds = Int(secondsFromStart * 1_000_000_000)
        DispatchQueue.main.asyncAfter(deadline: eventStartTime + .nanoseconds(nanoseconds)) { [weak self] in
            guard let self, sessionID == capturedSession else { return }
            delegate?.polyrhythmBeatFired(
                beatFired: beatFired,
                rhythmFired: rhythmFired,
                beatIndex: beatIndex,
                rhythmIndex: rhythmIndex,
            )
        }
    }
}
