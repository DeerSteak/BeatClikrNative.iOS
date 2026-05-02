//
//  PracticeHistoryUITests.swift
//  beatclikrUITests
//
//  Created by Ben Funk on 5/1/26.
//

import XCTest

@MainActor
final class PracticeHistoryUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() async throws {
        app = nil
    }

    // Navigates to Practice History on both iPhone (tab bar) and iPad (sidebar).
    @MainActor private func navigateToPracticeHistory() {
        let historyTab = app.tabBars.buttons["History"]
        if historyTab.waitForExistence(timeout: 2) {
            historyTab.tap()
        } else {
            app.buttons["Practice History"].tap()
        }
    }

    @MainActor func testHistoryTabExistsInTabBar() {
        XCTAssertTrue(
            app.tabBars.buttons["History"].waitForExistence(timeout: 3),
            "History tab should exist in the tab bar"
        )
    }

    @MainActor func testNavigationTitleShowsPracticeHistory() {
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.navigationBars["Practice History"].waitForExistence(timeout: 3),
            "Practice History navigation bar title should be visible"
        )
    }

    @MainActor func testCurrentStreakLabelIsVisible() {
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.staticTexts["Current Streak"].waitForExistence(timeout: 3),
            "Current Streak label should be visible"
        )
    }

    @MainActor func testLongestStreakLabelIsVisible() {
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.staticTexts["Longest Streak"].waitForExistence(timeout: 3),
            "Longest Streak label should be visible"
        )
    }

    @MainActor func testPracticeSectionAppearsForSelectedDate() {
        navigateToPracticeHistory()
        // The view defaults to today selected. Either songs or the empty state label will appear.
        let noPractice = app.staticTexts["No practice recorded"]
        let hasPracticeList = app.tables.firstMatch
        let appeared = noPractice.waitForExistence(timeout: 3) || hasPracticeList.waitForExistence(timeout: 3)
        XCTAssertTrue(appeared, "A practice section should be displayed for the selected date")
    }
}
