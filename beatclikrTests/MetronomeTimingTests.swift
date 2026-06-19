//
//  MetronomeTimingTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 4/10/26.
//

@testable import BeatClikr
import XCTest

final class MetronomeTimingTests: XCTestCase {
    // MARK: - Subdivision Duration Tests

    func testSubdivisionDurationCalculation() {
        // Formula: 60.0 / (bpm * subdivisions)

        // Test 60 BPM with quarter notes (1 subdivision)
        let duration60Quarter = 60.0 / (60.0 * 1.0)
        XCTAssertEqual(duration60Quarter, 1.0, accuracy: 0.001, "60 BPM quarter notes should be 1 second apart")

        // Test 120 BPM with quarter notes
        let duration120Quarter = 60.0 / (120.0 * 1.0)
        XCTAssertEqual(duration120Quarter, 0.5, accuracy: 0.001, "120 BPM quarter notes should be 0.5 seconds apart")

        // Test 120 BPM with eighth notes (2 subdivisions)
        let duration120Eighth = 60.0 / (120.0 * 2.0)
        XCTAssertEqual(duration120Eighth, 0.25, accuracy: 0.001, "120 BPM eighth notes should be 0.25 seconds apart")

        // Test 90 BPM with triplets (3 subdivisions)
        let duration90Triplet = 60.0 / (90.0 * 3.0)
        XCTAssertEqual(duration90Triplet, 0.222, accuracy: 0.001, "90 BPM triplets should be ~0.222 seconds apart")

        // Test 180 BPM with sixteenth notes (4 subdivisions)
        let duration180Sixteenth = 60.0 / (180.0 * 4.0)
        XCTAssertEqual(duration180Sixteenth, 0.0833, accuracy: 0.001, "180 BPM sixteenth notes should be ~0.0833 seconds apart")
    }

    func testBeatDurationForAnimation() {
        // Beat duration for animation is always 60.0 / bpm (regardless of subdivisions)

        // Test 60 BPM
        let beat60 = 60.0 / 60.0
        XCTAssertEqual(beat60, 1.0, accuracy: 0.001, "60 BPM beat should last 1 second")

        // Test 120 BPM
        let beat120 = 60.0 / 120.0
        XCTAssertEqual(beat120, 0.5, accuracy: 0.001, "120 BPM beat should last 0.5 seconds")

        // Test 180 BPM
        let beat180 = 60.0 / 180.0
        XCTAssertEqual(beat180, 0.333, accuracy: 0.001, "180 BPM beat should last ~0.333 seconds")

        // Test edge cases
        let beatMin = 60.0 / MetronomeConstants.minBPM
        XCTAssertEqual(beatMin, 2.0, accuracy: 0.001, "30 BPM beat should last 2 seconds")

        let beatMax = 60.0 / MetronomeConstants.maxBPM
        XCTAssertEqual(beatMax, 0.25, accuracy: 0.001, "240 BPM beat should last 0.25 seconds")
    }

    // MARK: - Scheduled Audio Timing Tests

    func testFirstBeatDelayIsReasonable() {
        XCTAssertGreaterThan(MetronomeConstants.firstBeatDelay, 0,
                             "First beat delay should be positive")
        let slowestBeat = 60.0 / MetronomeConstants.minBPM
        XCTAssertLessThan(MetronomeConstants.firstBeatDelay, slowestBeat,
                          "First beat delay should be shorter than the slowest possible beat")
    }

    // MARK: - Edge Case Tests

    func testExtremelySlowTempo() {
        // Test minimum BPM
        let duration = 60.0 / MetronomeConstants.minBPM
        XCTAssertGreaterThan(duration, 0, "Duration should be positive even at minimum BPM")
        XCTAssertLessThan(duration, 10, "Duration should be reasonable even at minimum BPM")
    }

    func testExtremelyFastTempo() {
        // Test maximum BPM with maximum subdivisions
        let duration = 60.0 / (MetronomeConstants.maxBPM * 4.0)
        XCTAssertGreaterThan(duration, 0, "Duration should be positive even at maximum speed")
        XCTAssertGreaterThan(duration, 0.01,
                             "Duration should remain practical for scheduled audio events")
    }
}
