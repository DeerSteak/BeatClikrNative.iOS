//
//  SequencerConfigurationTests.swift
//  beatclikrTests
//

@testable import BeatClikr
import Testing

struct SequencerConfigurationTests {
    // MARK: - Defaults

    @Test func `default tempo is 120`() {
        #expect(SequencerConfiguration().tempo == 120.0)
    }

    @Test func `default beats per measure is 4`() {
        #expect(SequencerConfiguration().beatsPerMeasure == 4)
    }

    @Test func `default measures count is 4`() {
        #expect(SequencerConfiguration().measuresCount == 4)
    }

    @Test func `default subdivisions per beat is 4`() {
        #expect(SequencerConfiguration().subdivisionsPerBeat == 4)
    }

    // MARK: - totalSteps

    @Test func `total steps is product of beats measures subdivisions`() {
        let config = SequencerConfiguration(tempo: 120, beatsPerMeasure: 4, measuresCount: 4, subdivisionsPerBeat: 4)
        #expect(config.totalSteps == 64)
    }

    @Test func `total steps with 1 measure 1 beat 1 subdivision`() {
        let config = SequencerConfiguration(tempo: 120, beatsPerMeasure: 1, measuresCount: 1, subdivisionsPerBeat: 1)
        #expect(config.totalSteps == 1)
    }

    @Test func `total steps with max values`() {
        let config = SequencerConfiguration(tempo: 240, beatsPerMeasure: 8, measuresCount: 8, subdivisionsPerBeat: 4)
        #expect(config.totalSteps == 256)
    }

    // MARK: - validate

    @Test func `default configuration is valid`() {
        #expect(SequencerConfiguration().validate())
    }

    @Test func `tempo below 40 is invalid`() {
        var c = SequencerConfiguration()
        c.tempo = 39
        #expect(!c.validate())
    }

    @Test func `tempo of 40 is valid`() {
        var c = SequencerConfiguration()
        c.tempo = 40
        #expect(c.validate())
    }

    @Test func `tempo of 240 is valid`() {
        var c = SequencerConfiguration()
        c.tempo = 240
        #expect(c.validate())
    }

    @Test func `tempo above 240 is invalid`() {
        var c = SequencerConfiguration()
        c.tempo = 241
        #expect(!c.validate())
    }

    @Test func `beats per measure of 0 is invalid`() {
        var c = SequencerConfiguration()
        c.beatsPerMeasure = 0
        #expect(!c.validate())
    }

    @Test func `beats per measure of 8 is valid`() {
        var c = SequencerConfiguration()
        c.beatsPerMeasure = 8
        #expect(c.validate())
    }

    @Test func `beats per measure of 9 is invalid`() {
        var c = SequencerConfiguration()
        c.beatsPerMeasure = 9
        #expect(!c.validate())
    }

    @Test func `measures count of 0 is invalid`() {
        var c = SequencerConfiguration()
        c.measuresCount = 0
        #expect(!c.validate())
    }

    @Test func `measures count of 8 is valid`() {
        var c = SequencerConfiguration()
        c.measuresCount = 8
        #expect(c.validate())
    }

    @Test func `subdivisions per beat of 0 is invalid`() {
        var c = SequencerConfiguration()
        c.subdivisionsPerBeat = 0
        #expect(!c.validate())
    }

    @Test func `subdivisions per beat of 4 is valid`() {
        var c = SequencerConfiguration()
        c.subdivisionsPerBeat = 4
        #expect(c.validate())
    }

    @Test func `subdivisions per beat of 5 is invalid`() {
        var c = SequencerConfiguration()
        c.subdivisionsPerBeat = 5
        #expect(!c.validate())
    }

    // MARK: - Equatable

    @Test func `two default configs are equal`() {
        #expect(SequencerConfiguration() == SequencerConfiguration())
    }

    @Test func `configs with different tempos are not equal`() {
        var other = SequencerConfiguration()
        other.tempo = 140
        #expect(SequencerConfiguration() != other)
    }
}
