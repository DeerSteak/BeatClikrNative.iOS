//
//  ImageConstantsTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 4/10/26.
//

import XCTest
@testable import beatclikr

final class ImageConstantsTests: XCTestCase {

    func testBeatIconExists() {
        XCTAssertFalse(ImageConstants.beat.isEmpty, "Beat icon name should not be empty")
        XCTAssertEqual(ImageConstants.beat, "diamond.fill", "Beat icon should be diamond.fill")
    }

    func testRhythmIconExists() {
        XCTAssertFalse(ImageConstants.rhythm.isEmpty, "Rhythm icon name should not be empty")
        XCTAssertEqual(ImageConstants.rhythm, "circle.fill", "Rhythm icon should be circle.fill")
    }

    func testIconsAreDifferent() {
        XCTAssertNotEqual(ImageConstants.beat, ImageConstants.rhythm, "Beat and rhythm icons should be different")
    }

    func testIconsAreValidSFSymbols() {
        // These are valid SF Symbols as of iOS 15+
        let validSymbols = ["diamond.fill", "circle.fill"]

        XCTAssertTrue(validSymbols.contains(ImageConstants.beat), "Beat icon should be a valid SF Symbol")
        XCTAssertTrue(validSymbols.contains(ImageConstants.rhythm), "Rhythm icon should be a valid SF Symbol")
    }
}
