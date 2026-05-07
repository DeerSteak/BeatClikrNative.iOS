//
//  FormatterHelperTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 5/7/26.
//

@testable import BeatClikr
import XCTest

final class FormatterHelperTests: XCTestCase {
    // MARK: - formatDouble

    func testWholeNumber() {
        XCTAssertEqual(FormatterHelper.formatDouble(120.0), "120")
    }

    func testZero() {
        XCTAssertEqual(FormatterHelper.formatDouble(0.0), "0")
    }

    func testOneFractionDigit() {
        XCTAssertEqual(FormatterHelper.formatDouble(120.5), "120.5")
    }

    func testTwoFractionDigits() {
        XCTAssertEqual(FormatterHelper.formatDouble(1.25), "1.25")
    }

    func testTruncatesAfterTwoFractionDigits() {
        // maximumFractionDigits = 2, so 1.005 rounds to 2 decimal places
        let result = FormatterHelper.formatDouble(1.234)
        XCTAssertEqual(result, "1.23")
    }

    func testNoTrailingZeros() {
        // minimumFractionDigits = 0, so 1.50 should format as "1.5"
        XCTAssertEqual(FormatterHelper.formatDouble(1.50), "1.5")
    }

    func testNegativeNumber() {
        XCTAssertEqual(FormatterHelper.formatDouble(-60.0), "-60")
    }

    func testLargeNumber() {
        XCTAssertEqual(FormatterHelper.formatDouble(1000.0), "1,000")
    }

    // MARK: - formatNumber

    func testFormatNSNumber() {
        XCTAssertEqual(FormatterHelper.formatNumber(120), "120")
        XCTAssertEqual(FormatterHelper.formatNumber(0), "0")
        XCTAssertEqual(FormatterHelper.formatNumber(1.5), "1.5")
    }
}
