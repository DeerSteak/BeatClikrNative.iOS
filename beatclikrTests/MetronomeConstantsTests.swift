//
//  MetronomeConstantsTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 4/10/26.
//

import XCTest
@testable import BeatClikr

final class MetronomeConstantsTests: XCTestCase {

    func testBPMConstraints() {
        // Verify BPM constraints are sensible
        XCTAssertEqual(MetronomeConstants.minBPM, 30, "Minimum BPM should be 30")
        XCTAssertEqual(MetronomeConstants.maxBPM, 240, "Maximum BPM should be 240")
        XCTAssertLessThan(MetronomeConstants.minBPM, MetronomeConstants.maxBPM, "Min BPM should be less than max BPM")
    }

    func testAnimationScales() {
        // Verify animation scales are valid
        XCTAssertGreaterThan(MetronomeConstants.iconScaleMin, 0, "Min scale should be positive")
        XCTAssertLessThanOrEqual(MetronomeConstants.iconScaleMin, 1, "Min scale should be <= 1")
        XCTAssertGreaterThan(MetronomeConstants.iconScaleMax, 0, "Max scale should be positive")
        XCTAssertLessThanOrEqual(MetronomeConstants.iconScaleMax, 1, "Max scale should be <= 1")
        XCTAssertLessThan(MetronomeConstants.iconScaleMin, MetronomeConstants.iconScaleMax, "Min scale should be less than max scale")
    }

    func testTimingValues() {
        // Verify timing values are reasonable
        XCTAssertGreaterThan(MetronomeConstants.timerCheckInterval, 0, "Timer check interval should be positive")
        XCTAssertLessThan(MetronomeConstants.timerCheckInterval, 0.1, "Timer check interval should be less than 100ms")

        XCTAssertGreaterThan(MetronomeConstants.firstBeatDelay, 0, "First beat delay should be positive")
        XCTAssertLessThan(MetronomeConstants.firstBeatDelay, 0.5, "First beat delay should be less than 500ms")

        XCTAssertGreaterThan(MetronomeConstants.lookaheadTolerance, 0, "Lookahead tolerance should be positive")
        XCTAssertLessThan(MetronomeConstants.lookaheadTolerance, 0.1, "Lookahead tolerance should be less than 100ms")
    }

    func testViewSizing() {
        // Verify view sizes are reasonable
        XCTAssertGreaterThan(MetronomeConstants.playerViewDefaultSize, 0, "Default size should be positive")
        XCTAssertGreaterThan(MetronomeConstants.playerViewToolbarSize, 0, "Toolbar size should be positive")
        XCTAssertLessThan(MetronomeConstants.playerViewToolbarSize, MetronomeConstants.playerViewDefaultSize, "Toolbar size should be smaller than default size")
    }
}
