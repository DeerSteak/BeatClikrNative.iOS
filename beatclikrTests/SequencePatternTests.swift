//
//  SequencePatternTests.swift
//  beatclikrTests
//

@testable import BeatClikr
import Testing

struct SequencePatternTests {
    private let defaultConfig = SequencerConfiguration()
    private let instruments: [FileConstants] = [.Kick, .Snare, .HatClosed, .HatOpen]

    private func makePattern(instruments: [FileConstants]? = nil, config: SequencerConfiguration? = nil) -> SequencePattern {
        SequencePattern(
            instruments: instruments ?? self.instruments,
            config: config ?? defaultConfig,
        )
    }

    // MARK: - Initialization

    @Test func `new pattern has all cells inactive`() {
        let pattern = makePattern()
        for step in 0 ..< defaultConfig.totalSteps {
            for instrument in instruments {
                #expect(pattern.isActive(instrument: instrument, at: step) == false)
            }
        }
    }

    @Test func `new pattern velocity is zero for all cells`() {
        let pattern = makePattern()
        for step in 0 ..< defaultConfig.totalSteps {
            #expect(pattern.velocity(instrument: .Kick, at: step) == 0)
        }
    }

    // MARK: - Toggle

    @Test func `toggle activates inactive cell`() {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: 0)
        #expect(pattern.isActive(instrument: .Kick, at: 0))
    }

    @Test func `toggle deactivates active cell`() {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: 0)
        pattern.toggle(instrument: .Kick, at: 0)
        #expect(!pattern.isActive(instrument: .Kick, at: 0))
    }

    @Test func `toggle sets velocity to 1`() {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: 0)
        #expect(pattern.velocity(instrument: .Kick, at: 0) == 1)
    }

    @Test func `toggle clears velocity to 0`() {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: 0)
        pattern.toggle(instrument: .Kick, at: 0)
        #expect(pattern.velocity(instrument: .Kick, at: 0) == 0)
    }

    @Test func `toggle does not affect other instruments`() {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: 0)
        #expect(!pattern.isActive(instrument: .Snare, at: 0))
    }

    @Test func `toggle does not affect other steps`() {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: 0)
        #expect(!pattern.isActive(instrument: .Kick, at: 1))
    }

    @Test func `toggle out of bounds does nothing`() {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: defaultConfig.totalSteps)
        // no crash, and in-bounds cells unaffected
        #expect(!pattern.isActive(instrument: .Kick, at: 0))
    }

    // MARK: - isActive / velocity bounds

    @Test func `isActive returns false for out of bounds step`() {
        let pattern = makePattern()
        #expect(!pattern.isActive(instrument: .Kick, at: defaultConfig.totalSteps))
    }

    @Test func `velocity returns 0 for out of bounds step`() {
        let pattern = makePattern()
        #expect(pattern.velocity(instrument: .Kick, at: defaultConfig.totalSteps) == 0)
    }

    // MARK: - updateConfig — shrink

    @Test func `shrink config preserves active cells within new bounds`() {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: 0)
        var smallConfig = defaultConfig
        smallConfig.measuresCount = 1 // 16 steps instead of 64
        pattern.updateConfig(smallConfig)
        #expect(pattern.isActive(instrument: .Kick, at: 0))
    }

    @Test func `shrink config hides cells beyond new total steps`() {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: 63) // last step of 64
        var smallConfig = defaultConfig
        smallConfig.measuresCount = 1 // only 16 steps visible
        pattern.updateConfig(smallConfig)
        #expect(!pattern.isActive(instrument: .Kick, at: 15))
    }

    // MARK: - updateConfig — expand restores data

    @Test func `expand config restores previously hidden cells`() {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: 63) // step beyond small config

        var smallConfig = defaultConfig
        smallConfig.measuresCount = 1
        pattern.updateConfig(smallConfig)

        // restore to original size
        pattern.updateConfig(defaultConfig)
        #expect(pattern.isActive(instrument: .Kick, at: 63))
    }

    @Test func `expand config fills new steps with zeros`() {
        var pattern = makePattern()
        var bigConfig = defaultConfig
        bigConfig.measuresCount = 8 // 128 steps
        pattern.updateConfig(bigConfig)
        // steps 64-127 were never set, should be inactive
        #expect(!pattern.isActive(instrument: .Kick, at: 64))
        #expect(!pattern.isActive(instrument: .Kick, at: 127))
    }

    // MARK: - Encode / Decode

    @Test func `encode then decode round trips empty pattern`() throws {
        let pattern = makePattern()
        let data = try pattern.encode()
        let decoded = try SequencePattern.decode(data, instruments: instruments, config: defaultConfig)
        for step in 0 ..< defaultConfig.totalSteps {
            for instrument in instruments {
                #expect(decoded.isActive(instrument: instrument, at: step) == false)
            }
        }
    }

    @Test func `encode then decode preserves active cells`() throws {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: 0)
        pattern.toggle(instrument: .Snare, at: 4)
        pattern.toggle(instrument: .HatClosed, at: 8)

        let data = try pattern.encode()
        let decoded = try SequencePattern.decode(data, instruments: instruments, config: defaultConfig)

        #expect(decoded.isActive(instrument: .Kick, at: 0))
        #expect(decoded.isActive(instrument: .Snare, at: 4))
        #expect(decoded.isActive(instrument: .HatClosed, at: 8))
        #expect(!decoded.isActive(instrument: .Kick, at: 1))
    }

    @Test func `encode then decode preserves velocity values`() throws {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: 0)

        let data = try pattern.encode()
        let decoded = try SequencePattern.decode(data, instruments: instruments, config: defaultConfig)
        #expect(decoded.velocity(instrument: .Kick, at: 0) == 1)
    }

    @Test func `decode with smaller config trims to new total steps`() throws {
        var pattern = makePattern()
        pattern.toggle(instrument: .Kick, at: 63)

        let data = try pattern.encode()
        var smallConfig = defaultConfig
        smallConfig.measuresCount = 1 // 16 steps
        let decoded = try SequencePattern.decode(data, instruments: instruments, config: smallConfig)
        #expect(!decoded.isActive(instrument: .Kick, at: 15))
    }
}
