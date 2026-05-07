//
//  BeatPatternTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 5/7/26.
//

@testable import BeatClikr
import XCTest

final class BeatPatternTests: XCTestCase {
    // MARK: - accentArray

    func testFiveEightA_3_2() {
        // "3,2" → [true,false,false, true,false]
        XCTAssertEqual(BeatPattern.fiveEightA.accentArray, [true, false, false, true, false])
    }

    func testFiveEightB_2_3() {
        // "2,3" → [true,false, true,false,false]
        XCTAssertEqual(BeatPattern.fiveEightB.accentArray, [true, false, true, false, false])
    }

    func testSevenEightA_3_2_2() {
        // "3,2,2" → [true,false,false, true,false, true,false]
        XCTAssertEqual(BeatPattern.sevenEightA.accentArray, [true, false, false, true, false, true, false])
    }

    func testSevenEightB_2_2_3() {
        // "2,2,3" → [true,false, true,false, true,false,false]
        XCTAssertEqual(BeatPattern.sevenEightB.accentArray, [true, false, true, false, true, false, false])
    }

    func testSevenEightC_2_3_2() {
        // "2,3,2" → [true,false, true,false,false, true,false]
        XCTAssertEqual(BeatPattern.sevenEightC.accentArray, [true, false, true, false, false, true, false])
    }

    func testNineEightB_3_3_3() {
        // "3,3,3" → [true,false,false, true,false,false, true,false,false]
        XCTAssertEqual(BeatPattern.nineEightB.accentArray, [true, false, false, true, false, false, true, false, false])
    }

    func testAccentArrayLengthMatchesTimeSignature() {
        // The total length of accentArray should equal the numerator of the time signature
        XCTAssertEqual(BeatPattern.fiveEightA.accentArray.count, 5)
        XCTAssertEqual(BeatPattern.fiveEightB.accentArray.count, 5)
        XCTAssertEqual(BeatPattern.sevenEightA.accentArray.count, 7)
        XCTAssertEqual(BeatPattern.sevenEightB.accentArray.count, 7)
        XCTAssertEqual(BeatPattern.sevenEightC.accentArray.count, 7)
        XCTAssertEqual(BeatPattern.nineEightA.accentArray.count, 9)
        XCTAssertEqual(BeatPattern.nineEightB.accentArray.count, 9)
        XCTAssertEqual(BeatPattern.elevenEightA.accentArray.count, 11)
        XCTAssertEqual(BeatPattern.elevenEightB.accentArray.count, 11)
        XCTAssertEqual(BeatPattern.thirteenEightA.accentArray.count, 13)
        XCTAssertEqual(BeatPattern.thirteenEightB.accentArray.count, 13)
        XCTAssertEqual(BeatPattern.fifteenEightA.accentArray.count, 15)
        XCTAssertEqual(BeatPattern.fifteenEightB.accentArray.count, 15)
    }

    func testFirstElementIsAlwaysAccented() {
        for pattern in BeatPattern.allCases {
            XCTAssertTrue(pattern.accentArray.first == true, "\(pattern.rawValue): first element should always be accented")
        }
    }

    func testAccentCountMatchesGroupCount() {
        // Number of `true` values should equal the number of comma-separated groups
        for pattern in BeatPattern.allCases {
            let groupCount = pattern.rawValue.split(separator: ",").count
            let accentCount = pattern.accentArray.count(where: { $0 })
            XCTAssertEqual(accentCount, groupCount, "\(pattern.rawValue): accent count should match group count")
        }
    }

    // MARK: - displayName

    func testDisplayNames() {
        XCTAssertEqual(BeatPattern.fiveEightA.displayName, "5 (3+2)")
        XCTAssertEqual(BeatPattern.fiveEightB.displayName, "5 (2+3)")
        XCTAssertEqual(BeatPattern.sevenEightA.displayName, "7 (3+2+2)")
        XCTAssertEqual(BeatPattern.sevenEightB.displayName, "7 (2+2+3)")
        XCTAssertEqual(BeatPattern.sevenEightC.displayName, "7 (2+3+2)")
        XCTAssertEqual(BeatPattern.nineEightA.displayName, "9 (2+2+2+3)")
        XCTAssertEqual(BeatPattern.nineEightB.displayName, "9 (3+3+3)")
        XCTAssertEqual(BeatPattern.elevenEightA.displayName, "11 (2+2+3+2+2)")
        XCTAssertEqual(BeatPattern.elevenEightB.displayName, "11 (3+3+2+3)")
        XCTAssertEqual(BeatPattern.thirteenEightA.displayName, "13 (3+2+2+3+3)")
        XCTAssertEqual(BeatPattern.thirteenEightB.displayName, "13 (2+3+2+3+3)")
        XCTAssertEqual(BeatPattern.fifteenEightA.displayName, "15 (3+3+3+3+3)")
        XCTAssertEqual(BeatPattern.fifteenEightB.displayName, "15 (2+3+2+3+2+3)")
    }

    // MARK: - rawValue / init

    func testInitFromRawValue() {
        XCTAssertEqual(BeatPattern(rawValue: "3,2"), .fiveEightA)
        XCTAssertEqual(BeatPattern(rawValue: "3,2,2"), .sevenEightA)
        XCTAssertNil(BeatPattern(rawValue: "invalid"))
    }
}
