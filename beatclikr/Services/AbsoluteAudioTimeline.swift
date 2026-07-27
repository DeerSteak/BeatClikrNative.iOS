//
//  AbsoluteAudioTimeline.swift
//  beatclikr
//

import AudioToolbox
import AVFoundation
import CoreAudio
import Foundation

/// Stable identity for one buffer in an engine-owned rolling pool.
///
/// AVAudioPlayerNode invokes completion handlers off the main actor. The handler
/// only transports this identity back to the main actor; all buffer reads and
/// writes remain main-actor isolated in the owning engine.
final class AudioBufferSlot: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer

    init(buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
    }
}

/// Converts musical event indices to independently rounded absolute sample positions.
struct AbsoluteAudioTimeline {
    let samplesPerInterval: Double

    init(sampleRate: Double, intervalsPerMinute: Double) throws {
        guard sampleRate > 0, intervalsPerMinute > 0 else {
            throw PlaybackError.invalidConfiguration
        }
        samplesPerInterval = sampleRate * 60 / intervalsPerMinute
    }

    func samplePosition(_ intervalIndex: Int64) -> Int64 {
        precondition(intervalIndex >= 0)
        return Int64((Double(intervalIndex) * samplesPerInterval).rounded())
    }
}

struct MetronomeAudioBlockPlan {
    struct Event {
        let absoluteSample: Int64
        let relativeSample: AVAudioFramePosition
        let maximumFrameLength: AVAudioFrameCount
        let isBeat: Bool
        let usesBeatSound: Bool
        let beatInterval: TimeInterval
    }

    let absoluteStartSample: Int64
    let frameCount: AVAudioFrameCount
    let events: [Event]

    init(
        blockIndex: Int64,
        sampleRate: Double,
        bpm: Double,
        subdivisions: Int,
        accentPattern: [Bool]?,
        alternateSixteenth: Bool,
    ) throws {
        guard blockIndex >= 0, subdivisions > 0 else {
            throw PlaybackError.invalidConfiguration
        }
        let timeline = try AbsoluteAudioTimeline(
            sampleRate: sampleRate,
            intervalsPerMinute: bpm * Double(subdivisions),
        )
        let pattern: [Bool] = if let accentPattern {
            accentPattern
        } else {
            (0 ..< subdivisions).map { $0 == 0 }
        }
        guard !pattern.isEmpty else {
            throw PlaybackError.invalidConfiguration
        }

        let intervalsPerBlock = Int64(pattern.count)
        let firstInterval = blockIndex * intervalsPerBlock
        let endInterval = firstInterval + intervalsPerBlock
        let blockStartSample = timeline.samplePosition(firstInterval)
        let absoluteEndSample = timeline.samplePosition(endInterval)
        absoluteStartSample = blockStartSample
        frameCount = AVAudioFrameCount(absoluteEndSample - blockStartSample)

        events = pattern.indices.map { patternIndex in
            let globalIndex = firstInterval + Int64(patternIndex)
            let absoluteSample = timeline.samplePosition(globalIndex)
            let nextAbsoluteSample = timeline.samplePosition(globalIndex + 1)
            let isBeat = pattern[patternIndex]
            let usesBeatSound = accentPattern != nil
                ? isBeat
                : alternateSixteenth && subdivisions == 4
                ? patternIndex % 2 == 0
                : patternIndex == 0

            var intervalsToNextBeat = 1
            if isBeat {
                while !pattern[(patternIndex + intervalsToNextBeat) % pattern.count],
                      intervalsToNextBeat < pattern.count
                {
                    intervalsToNextBeat += 1
                }
            }

            return Event(
                absoluteSample: absoluteSample,
                relativeSample: absoluteSample - blockStartSample,
                maximumFrameLength: AVAudioFrameCount(nextAbsoluteSample - absoluteSample),
                isBeat: isBeat,
                usesBeatSound: usesBeatSound,
                beatInterval: Double(intervalsToNextBeat) * timeline.samplesPerInterval / sampleRate,
            )
        }
    }
}

struct PolyrhythmAudioBlockPlan {
    struct Event {
        let absoluteSample: Int64
        let relativeSample: AVAudioFramePosition
        let maximumFrameLength: AVAudioFrameCount
        let index: Int
    }

    let absoluteStartSample: Int64
    let frameCount: AVAudioFrameCount
    let beatEvents: [Event]
    let rhythmEvents: [Event]

    init(blockIndex: Int64, sampleRate: Double, bpm: Double, beats: Int, against: Int) throws {
        guard blockIndex >= 0, beats > 0, against > 0 else {
            throw PlaybackError.invalidConfiguration
        }

        let beatTimeline = try AbsoluteAudioTimeline(sampleRate: sampleRate, intervalsPerMinute: bpm)
        let rhythmTimeline = try AbsoluteAudioTimeline(
            sampleRate: sampleRate,
            intervalsPerMinute: bpm * Double(beats) / Double(against),
        )
        let firstBeat = blockIndex * Int64(against)
        let firstRhythm = blockIndex * Int64(beats)
        let blockStartSample = beatTimeline.samplePosition(firstBeat)
        let absoluteEndSample = beatTimeline.samplePosition(firstBeat + Int64(against))
        absoluteStartSample = blockStartSample
        frameCount = AVAudioFrameCount(absoluteEndSample - blockStartSample)

        beatEvents = (0 ..< against).map { index in
            let globalIndex = firstBeat + Int64(index)
            let absoluteSample = beatTimeline.samplePosition(globalIndex)
            return Event(
                absoluteSample: absoluteSample,
                relativeSample: absoluteSample - blockStartSample,
                maximumFrameLength: AVAudioFrameCount(
                    beatTimeline.samplePosition(globalIndex + 1) - absoluteSample,
                ),
                index: index,
            )
        }
        rhythmEvents = (0 ..< beats).map { index in
            let globalIndex = firstRhythm + Int64(index)
            let absoluteSample = rhythmTimeline.samplePosition(globalIndex)
            return Event(
                absoluteSample: absoluteSample,
                relativeSample: absoluteSample - blockStartSample,
                maximumFrameLength: AVAudioFrameCount(
                    rhythmTimeline.samplePosition(globalIndex + 1) - absoluteSample,
                ),
                index: index,
            )
        }
    }
}

enum AudioBlockRenderer {
    static func clear(_ destination: AVAudioPCMBuffer, frameCount: AVAudioFrameCount) {
        destination.frameLength = frameCount
        for buffer in UnsafeMutableAudioBufferListPointer(destination.mutableAudioBufferList) {
            guard let data = buffer.mData else { continue }
            memset(data, 0, Int(buffer.mDataByteSize))
        }
    }

    static func mix(
        _ source: AVAudioPCMBuffer,
        at offset: AVAudioFramePosition,
        into destination: AVAudioPCMBuffer,
    ) {
        guard offset >= 0,
              offset < destination.frameLength,
              source.format == destination.format,
              let sourceChannels = source.floatChannelData,
              let destinationChannels = destination.floatChannelData
        else {
            return
        }

        let availableFrames = Int(destination.frameLength) - Int(offset)
        let framesToCopy = min(Int(source.frameLength), availableFrames)
        for channel in 0 ..< Int(destination.format.channelCount) {
            let sourceChannel = sourceChannels[channel]
            let destinationChannel = destinationChannels[channel].advanced(by: Int(offset))
            for frame in 0 ..< framesToCopy {
                destinationChannel[frame] += sourceChannel[frame]
            }
        }
    }
}
