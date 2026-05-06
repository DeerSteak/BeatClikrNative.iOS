//
//  AudioKitPolyrhythmEngine.swift
//  beatclikr
//

import Foundation
import AudioKit

/// Polyrhythm engine using a least-common-multiple grid.
///
/// For M against N:
///   - Cycle = N quarter notes
///   - Grid = LCM(M, N) equal steps
///   - Beat sound fires every LCM/N steps
///   - Rhythm sound fires every LCM/M steps
@MainActor
class AudioKitPolyrhythmEngine: PolyrhythmAudioEngine {
    private let sampler: AppleSampler

    private var beatSound: SoundFile?
    private var rhythmSound: SoundFile?

    private weak var delegate: PolyrhythmAudioEngineDelegate?
    private var isPlaying = false

    private var timer: Timer?
    private var nextStepTime: CFAbsoluteTime = 0
    private var stepIndex: Int = 0

    private var lcmValue: Int = 6
    private var beatGridStep: Int = 3    // beat fires every N steps
    private var rhythmGridStep: Int = 2  // rhythm fires every N steps
    private var stepDuration: Double = 0

    private let checkInterval = MetronomeConstants.timerCheckInterval
    private let firstBeatDelay = MetronomeConstants.firstBeatDelay
    private let lookaheadTolerance = MetronomeConstants.lookaheadTolerance

    init(sampler: AppleSampler) {
        self.sampler = sampler
    }

    func loadSounds(beatName: String, rhythmName: String, from sounds: [SoundFile]) {
        beatSound = sounds.first { $0.displayName == beatName }
        rhythmSound = sounds.first { $0.displayName == rhythmName }
    }

    func startPolyrhythm(bpm: Double, beats: Int, against: Int, delegate: PolyrhythmAudioEngineDelegate) {
        timer?.invalidate()
        timer = nil

        self.delegate = delegate

        let lc = computeLCM(beats, against)
        lcmValue = lc
        beatGridStep = lc / against
        rhythmGridStep = lc / beats
        // Total cycle = against quarter notes; divide into lcm equal steps
        stepDuration = Double(against) * (60.0 / bpm) / Double(lc)

        stepIndex = 0
        nextStepTime = CFAbsoluteTimeGetCurrent() + firstBeatDelay
        isPlaying = true
        startTimer()
    }

    func stopPolyrhythm() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        stepIndex = 0
    }

    // MARK: - Private helpers

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndPlayStep()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func checkAndPlayStep() {
        guard isPlaying else {
            timer?.invalidate()
            timer = nil
            return
        }

        let now = CFAbsoluteTimeGetCurrent()
        guard now >= nextStepTime - lookaheadTolerance else { return }

        playCurrentStep()
        nextStepTime = now + stepDuration
        stepIndex = (stepIndex + 1) % lcmValue
    }

    private func playCurrentStep() {
        let isBeatStep = stepIndex % beatGridStep == 0
        let isRhythmStep = stepIndex % rhythmGridStep == 0

        guard isBeatStep || isRhythmStep else { return }

        if !UserDefaultsService.instance.muteMetronome {
            if isBeatStep, let beatSound {
                sampler.play(noteNumber: MIDINoteNumber(beatSound.midiNote))
            }
            if isRhythmStep, let rhythmSound {
                sampler.play(noteNumber: MIDINoteNumber(rhythmSound.midiNote))
            }
        }

        delegate?.polyrhythmBeatFired(
            beatFired: isBeatStep,
            rhythmFired: isRhythmStep,
            beatIndex: stepIndex / beatGridStep,
            rhythmIndex: stepIndex / rhythmGridStep
        )
    }

    private func computeLCM(_ a: Int, _ b: Int) -> Int {
        a / computeGCD(a, b) * b
    }

    private func computeGCD(_ a: Int, _ b: Int) -> Int {
        var a = a, b = b
        while b != 0 { (a, b) = (b, a % b) }
        return a
    }
}
