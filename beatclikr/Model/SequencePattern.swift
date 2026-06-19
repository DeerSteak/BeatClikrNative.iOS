//
//  SequencePattern.swift
//  beatclikr
//
//  Created by Ben Funk on 6/19/26.
//

import Foundation

struct SequencePattern {
    private var pattern: [String: [UInt8]] // 0=off, 1-3=velocity (v1 uses 0/1 only)
    private var fullPattern: [String: [UInt8]] // Never truncated, preserves data on config shrink
    let instruments: [FileConstants]
    var config: SequencerConfiguration

    init(instruments: [FileConstants], config: SequencerConfiguration) {
        self.instruments = instruments
        self.config = config
        pattern = [:]
        fullPattern = [:]

        for instrument in instruments {
            let key = instrument.rawValue
            pattern[key] = Array(repeating: 0, count: config.totalSteps)
            fullPattern[key] = Array(repeating: 0, count: config.totalSteps)
        }
    }

    mutating func toggle(instrument: FileConstants, at step: Int) {
        let key = instrument.rawValue
        guard step < config.totalSteps else { return }

        var array = pattern[key] ?? Array(repeating: 0, count: config.totalSteps)
        array[step] = array[step] == 0 ? 1 : 0 // v1: binary toggle
        pattern[key] = array
        fullPattern[key] = array // Keep full pattern synced
    }

    func isActive(instrument: FileConstants, at step: Int) -> Bool {
        guard step < config.totalSteps else { return false }
        return (pattern[instrument.rawValue]?[step] ?? 0) > 0
    }

    func velocity(instrument: FileConstants, at step: Int) -> UInt8 {
        guard step < config.totalSteps else { return 0 }
        return pattern[instrument.rawValue]?[step] ?? 0
    }

    mutating func updateConfig(_ newConfig: SequencerConfiguration) {
        config = newConfig

        // Resize pattern arrays (expand or show only visible portion)
        for instrument in instruments {
            let key = instrument.rawValue
            var array = fullPattern[key] ?? []

            if newConfig.totalSteps > array.count {
                // Expand full pattern
                array.append(contentsOf: Array(repeating: 0, count: newConfig.totalSteps - array.count))
                fullPattern[key] = array
            }

            // Pattern shows only visible portion
            pattern[key] = Array(array.prefix(newConfig.totalSteps))
        }
    }

    func encode() throws -> Data {
        try JSONEncoder().encode(pattern)
    }

    static func decode(_ data: Data, instruments: [FileConstants], config: SequencerConfiguration) throws -> SequencePattern {
        var sequencePattern = SequencePattern(instruments: instruments, config: config)
        let decoded = try JSONDecoder().decode([String: [UInt8]].self, from: data)

        for instrument in instruments {
            let key = instrument.rawValue
            if let array = decoded[key] {
                sequencePattern.pattern[key] = Array(array.prefix(config.totalSteps))
                sequencePattern.fullPattern[key] = array
            }
        }

        return sequencePattern
    }
}
