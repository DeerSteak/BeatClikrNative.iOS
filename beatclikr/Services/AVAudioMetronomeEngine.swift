//
//  AVAudioMetronomeEngine.swift
//  beatclikr
//
//  Created by Ben Funk on 4/10/26.
//

import Foundation
import AudioKit
import AVFoundation

/// Sample-accurate metronome using AVAudioPlayerNode with host-time scheduling.
/// Each beat is a pre-computed buffer: the click sample followed by zero-padded silence
/// to fill exactly one subdivision duration. Scheduling one full-subdivision buffer per
/// beat keeps the single player node continuously active (no stopped-node drops) while
/// using only one rendering stream (vs. the previous 4-node pool).
class AVAudioMetronomeEngine: MetronomeAudioEngine, @unchecked Sendable {
    private let engine: AudioEngine
    private let silentOutput = Mixer()
    private let playerNode = AVAudioPlayerNode()

    // Raw click samples decoded from the audio files.
    nonisolated(unsafe) private var rawBeatBuffer: AVAudioPCMBuffer?
    nonisolated(unsafe) private var rawRhythmBuffer: AVAudioPCMBuffer?

    // Beat-length buffers: click padded with silence to fill exactly one subdivision.
    // Pre-computed so the render thread only reads from memory on each beat.
    nonisolated(unsafe) private var beatBuffer: AVAudioPCMBuffer?
    nonisolated(unsafe) private var rhythmBuffer: AVAudioPCMBuffer?
    nonisolated(unsafe) private var silentBuffer: AVAudioPCMBuffer?

    // Subdivision seconds used to build the beat-length buffers.
    // Written and read exclusively on the main thread.
    nonisolated(unsafe) private var subdivisionSeconds: Double = 0

    nonisolated(unsafe) private weak var delegate: MetronomeAudioEngineDelegate?

    // Incremented on main thread in startMetronome/stopMetronome.
    // Captured by each visual asyncAfter so stale callbacks from old sessions self-invalidate.
    nonisolated(unsafe) private var visualSessionID: Int = 0

    private let schedulingQueue = DispatchQueue(label: "com.beatclikr.metronome", qos: .userInteractive)

    // All mutable scheduling state lives exclusively on schedulingQueue:
    private var isPlaying = false
    private var currentBPM: Double = 60
    private var currentSubdivisions: Int = 1
    private var subdivisionCounter: Int = 0
    private var nextBeatHostTime: UInt64 = 0
    private var sessionID: Int = 0

    private let timebaseInfo: mach_timebase_info_data_t = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()

    init(engine: AudioEngine) {
        self.engine = engine
        engine.output = silentOutput
        engine.avEngine.attach(playerNode)
        engine.avEngine.connect(playerNode, to: engine.avEngine.mainMixerNode, format: nil)
    }

    func loadSounds(beatName: String, rhythmName: String, from sounds: [SoundFile]) {
        rawBeatBuffer = makeRawBuffer(for: sounds.first { $0.displayName == beatName })
        rawRhythmBuffer = makeRawBuffer(for: sounds.first { $0.displayName == rhythmName })
        // If a tempo is already set (metronome was running), rebuild the beat-length buffers
        // immediately so the new sound takes effect on the next scheduled beat.
        if subdivisionSeconds > 0 {
            recomputeBeatBuffers()
        }
    }

    // Called from @MainActor — node control stays on main thread to avoid internal handler errors
    func startMetronome(bpm: Double, subdivisions: Int, delegate: MetronomeAudioEngineDelegate) {
        playerNode.stop()
        playerNode.play()
        self.delegate = delegate
        visualSessionID += 1
        subdivisionSeconds = 60.0 / (bpm * Double(subdivisions))
        recomputeBeatBuffers()

        schedulingQueue.async { [weak self] in
            guard let self else { return }
            self.sessionID += 1
            let session = self.sessionID
            self.isPlaying = true
            self.currentBPM = bpm
            self.currentSubdivisions = subdivisions
            self.subdivisionCounter = 0
            self.nextBeatHostTime = mach_absolute_time() + self.secondsToHostTicks(MetronomeConstants.firstBeatDelay)
            self.scheduleNextBeat(session: session)
        }
    }

    func stopMetronome() {
        playerNode.stop()
        playerNode.play()
        visualSessionID += 1
        schedulingQueue.async { [weak self] in
            guard let self else { return }
            self.isPlaying = false
            self.sessionID += 1
            self.subdivisionCounter = 0
        }
    }

    func updateTempo(bpm: Double, subdivisions: Int) {
        schedulingQueue.async { [weak self] in
            self?.currentBPM = bpm
            self?.currentSubdivisions = subdivisions
        }
    }

    func start() throws {
        try engine.start()
        playerNode.play()
    }

    func stop() {
        engine.stop()
    }

    // MARK: - Private scheduling (always runs on schedulingQueue)

    private func scheduleNextBeat(session: Int) {
        guard isPlaying, session == sessionID else { return }

        let isBeat = subdivisionCounter == 0
        let beatHostTime = nextBeatHostTime
        let beatNanoseconds = hostTicksToNanoseconds(beatHostTime)
        let capturedVisualSession = visualSessionID

        // Visual/haptic fires at the exact host time the audio plays.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: beatNanoseconds)) { [weak self] in
            guard let self, self.visualSessionID == capturedVisualSession else { return }
            MainActor.assumeIsolated {
                self.delegate?.metronomeBeatFired(isBeat: isBeat)
            }
        }

        let secondsPerSubdivision = 60.0 / (currentBPM * Double(currentSubdivisions))
        nextBeatHostTime += secondsToHostTicks(secondsPerSubdivision)
        subdivisionCounter = (subdivisionCounter + 1) % currentSubdivisions

        // Always schedule a buffer — silence when muted — so the node stays continuously active
        // between beats. .interrupts at each host time boundary handles any tiny frame-rounding
        // overlap between the outgoing buffer's silence tail and the incoming buffer.
        let isMuted = UserDefaults.standard.bool(forKey: PreferenceKeys.muteMetronome)
        let buffer = isMuted ? silentBuffer : (isBeat ? beatBuffer : rhythmBuffer)
        if let buffer {
            playerNode.scheduleBuffer(buffer, at: AVAudioTime(hostTime: beatHostTime), options: .interrupts)
        }

        let nextNs = hostTicksToNanoseconds(nextBeatHostTime)
        schedulingQueue.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: nextNs)) { [weak self] in
            self?.scheduleNextBeat(session: session)
        }
    }

    // MARK: - Private helpers

    // Called on the main thread from loadSounds and startMetronome.
    private func recomputeBeatBuffers() {
        guard let format = rawBeatBuffer?.format ?? rawRhythmBuffer?.format,
              subdivisionSeconds > 0 else { return }
        let totalFrames = AVAudioFrameCount(subdivisionSeconds * format.sampleRate)
        beatBuffer   = makeBeatLengthBuffer(click: rawBeatBuffer,   format: format, totalFrames: totalFrames)
        rhythmBuffer = makeBeatLengthBuffer(click: rawRhythmBuffer, format: format, totalFrames: totalFrames)
        silentBuffer = makeBeatLengthBuffer(click: nil,             format: format, totalFrames: totalFrames)
    }

    private func makeRawBuffer(for sound: SoundFile?) -> AVAudioPCMBuffer? {
        guard let audioFile = sound?.audioFile else { return nil }
        let frameCount = AVAudioFrameCount(audioFile.length)
        guard frameCount > 0 else { return nil }
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: audioFile.processingFormat.sampleRate,
            channels: audioFile.processingFormat.channelCount
        ) else { return nil }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        // Reset position — AVAudioFile cursor advances on each read
        audioFile.framePosition = 0
        do {
            try audioFile.read(into: buffer, frameCount: frameCount)
            return buffer
        } catch {
            print("Failed to read audio buffer: \(error)")
            return nil
        }
    }

    /// Builds a buffer of exactly `totalFrames` containing the click sample at the start,
    /// zero-padded to fill the remainder. Pass `click: nil` for a pure-silence buffer.
    private func makeBeatLengthBuffer(click: AVAudioPCMBuffer?, format: AVAudioFormat, totalFrames: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        guard totalFrames > 0 else { return nil }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else { return nil }
        buffer.frameLength = totalFrames
        let channelCount = Int(format.channelCount)
        for ch in 0..<channelCount {
            guard let dst = buffer.floatChannelData?[ch] else { continue }
            if let click, let src = click.floatChannelData?[ch] {
                let clickFrames = min(Int(click.frameLength), Int(totalFrames))
                dst.update(from: src, count: clickFrames)
                let silenceFrames = Int(totalFrames) - clickFrames
                if silenceFrames > 0 {
                    memset(dst + clickFrames, 0, silenceFrames * MemoryLayout<Float>.size)
                }
            } else {
                memset(dst, 0, Int(totalFrames) * MemoryLayout<Float>.size)
            }
        }
        return buffer
    }

    private func secondsToHostTicks(_ seconds: Double) -> UInt64 {
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        return nanoseconds * UInt64(timebaseInfo.denom) / UInt64(timebaseInfo.numer)
    }

    private func hostTicksToNanoseconds(_ ticks: UInt64) -> UInt64 {
        ticks * UInt64(timebaseInfo.numer) / UInt64(timebaseInfo.denom)
    }
}
