//
//  GrooveTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 5/7/26.
//

@testable import BeatClikr
import XCTest

final class GrooveTests: XCTestCase {
    // MARK: - subdivisions

    func testStandardGrooveSubdivisionsMatchRawValue() {
        XCTAssertEqual(Groove.quarter.subdivisions, 1)
        XCTAssertEqual(Groove.eighth.subdivisions, 2)
        XCTAssertEqual(Groove.triplet.subdivisions, 3)
        XCTAssertEqual(Groove.sixteenth.subdivisions, 4)
    }

    func testOddMeterQuarterSubdivisionsIsOne() {
        // oddMeterQuarter rawValue is 5, but subdivisions should be 1 (not 5)
        XCTAssertEqual(Groove.oddMeterQuarter.subdivisions, 1)
    }

    func testOddMeterEighthSubdivisionsIsTwo() {
        // oddMeterEighth rawValue is 6, but subdivisions should be 2 (not 6)
        XCTAssertEqual(Groove.oddMeterEighth.subdivisions, 2)
    }

    // MARK: - isOddMeter

    func testStandardGroovesAreNotOddMeter() {
        XCTAssertFalse(Groove.quarter.isOddMeter)
        XCTAssertFalse(Groove.eighth.isOddMeter)
        XCTAssertFalse(Groove.triplet.isOddMeter)
        XCTAssertFalse(Groove.sixteenth.isOddMeter)
    }

    func testOddMeterGroovesAreOddMeter() {
        XCTAssertTrue(Groove.oddMeterQuarter.isOddMeter)
        XCTAssertTrue(Groove.oddMeterEighth.isOddMeter)
    }

    // MARK: - description

    func testDescriptions() {
        XCTAssertEqual(Groove.quarter.description, "Quarter Note")
        XCTAssertEqual(Groove.eighth.description, "Eighth Note")
        XCTAssertEqual(Groove.triplet.description, "Triplet 6/8")
        XCTAssertEqual(Groove.sixteenth.description, "Sixteenth Note")
        XCTAssertEqual(Groove.oddMeterQuarter.description, "Odd Quarter")
        XCTAssertEqual(Groove.oddMeterEighth.description, "Odd Eighth")
    }

    // MARK: - rawValue / init

    func testRawValues() {
        XCTAssertEqual(Groove.quarter.rawValue, 1)
        XCTAssertEqual(Groove.eighth.rawValue, 2)
        XCTAssertEqual(Groove.triplet.rawValue, 3)
        XCTAssertEqual(Groove.sixteenth.rawValue, 4)
        XCTAssertEqual(Groove.oddMeterQuarter.rawValue, 5)
        XCTAssertEqual(Groove.oddMeterEighth.rawValue, 6)
    }

    func testInitFromRawValue() {
        XCTAssertEqual(Groove(rawValue: 1), .quarter)
        XCTAssertEqual(Groove(rawValue: 2), .eighth)
        XCTAssertEqual(Groove(rawValue: 5), .oddMeterQuarter)
        XCTAssertNil(Groove(rawValue: 0), "rawValue 0 should not map to any case")
        XCTAssertNil(Groove(rawValue: 7), "rawValue 7 should not map to any case")
    }
}
