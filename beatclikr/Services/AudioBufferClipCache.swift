//
//  AudioBufferClipCache.swift
//  beatclikr
//
//  Created by Ben Funk 7/27/26
//

import AudioToolbox
import AVFoundation
import CoreAudio
import Foundation

/// Owns one immutable loaded sample and immutable, reusable clips derived from it.
///
/// AVAudioPlayerNode may retain a scheduled buffer until playback consumes it. A
/// scheduler must therefore never change that buffer's frameLength in place.
final class AudioBufferClipCache {
    let source: AVAudioPCMBuffer

    private let maximumClipCount: Int
    private let maximumCachedBytes: Int
    private var clips: [AVAudioFrameCount: AVAudioPCMBuffer] = [:]
    private var recency: [AVAudioFrameCount] = []

    init(
        source: AVAudioPCMBuffer,
        maximumClipCount: Int = 16,
        maximumCachedBytes: Int = 2 * 1024 * 1024,
    ) {
        precondition(maximumClipCount > 0)
        precondition(maximumCachedBytes > 0)
        self.source = source
        self.maximumClipCount = maximumClipCount
        self.maximumCachedBytes = maximumCachedBytes
    }

    func buffer(maximumFrameLength: AVAudioFrameCount) -> AVAudioPCMBuffer {
        let requestedLength = min(maximumFrameLength, source.frameLength)
        guard requestedLength < source.frameLength else {
            return source
        }
        if let cached = clips[requestedLength] {
            markAsRecentlyUsed(requestedLength)
            return cached
        }
        guard let clip = AVAudioPCMBuffer(pcmFormat: source.format, frameCapacity: requestedLength) else {
            return source
        }

        clip.frameLength = requestedLength
        copyFrames(from: source, to: clip)
        clips[requestedLength] = clip
        recency.append(requestedLength)
        evictLeastRecentlyUsedClipsIfNeeded()
        return clip
    }

    var cachedClipCount: Int {
        clips.count
    }

    var cachedByteCount: Int {
        clips.values.reduce(0) { $0 + byteCount(of: $1) }
    }

    private func markAsRecentlyUsed(_ frameLength: AVAudioFrameCount) {
        recency.removeAll { $0 == frameLength }
        recency.append(frameLength)
    }

    private func evictLeastRecentlyUsedClipsIfNeeded() {
        while clips.count > 1,
              clips.count > maximumClipCount || cachedByteCount > maximumCachedBytes,
              let leastRecentlyUsed = recency.first
        {
            recency.removeFirst()
            clips[leastRecentlyUsed] = nil
        }
    }

    private func byteCount(of buffer: AVAudioPCMBuffer) -> Int {
        UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
            .reduce(0) { $0 + Int($1.mDataByteSize) }
    }

    private func copyFrames(from source: AVAudioPCMBuffer, to destination: AVAudioPCMBuffer) {
        let sourceBuffers = UnsafeMutableAudioBufferListPointer(source.mutableAudioBufferList)
        let destinationBuffers = UnsafeMutableAudioBufferListPointer(destination.mutableAudioBufferList)

        for (sourceBuffer, destinationBuffer) in zip(sourceBuffers, destinationBuffers) {
            guard let sourceData = sourceBuffer.mData, let destinationData = destinationBuffer.mData else {
                continue
            }
            let bytesToCopy = min(Int(sourceBuffer.mDataByteSize), Int(destinationBuffer.mDataByteSize))
            memcpy(destinationData, sourceData, bytesToCopy)
        }
    }
}
