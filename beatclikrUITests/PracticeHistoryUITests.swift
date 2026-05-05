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
    }
    
    override func tearDown() async throws {
        app = nil
    }
    
    private func launchApp(practiceState: String? = nil) {
        if let state = practiceState {
            app.launchEnvironment["UI_TESTING_PRACTICE_STATE"] = state
        }
        app.launch()
    }
    
    // Navigates to Practice History on both iPhone (tab bar) and iPad (sidebar).
    private func navigateToPracticeHistory() {
        let historyTab = app.tabBars.buttons["History"]
        if historyTab.waitForExistence(timeout: 2) {
            historyTab.tap()
        } else {
            app.buttons["Practice History"].tap()
        }
    }
    
    // MARK: - Navigation
    
    func testHistoryTabExistsInTabBar() {
        launchApp()
        XCTAssertTrue(
            app.tabBars.buttons["History"].waitForExistence(timeout: 3),
            "History tab should exist in the tab bar"
        )
    }
    
    func testNavigationTitleShowsPracticeHistory() {
        launchApp()
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.navigationBars["Practice History"].waitForExistence(timeout: 3),
            "Practice History navigation bar title should be visible"
        )
    }
    
    // MARK: - Streak stats
    
    func testCurrentStreakLabelIsVisible() {
        launchApp(practiceState: "empty")
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.staticTexts["Current Streak"].waitForExistence(timeout: 3),
            "Current Streak label should be visible"
        )
    }
    
    func testLongestStreakLabelIsVisible() {
        launchApp(practiceState: "empty")
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.staticTexts["Longest Streak"].waitForExistence(timeout: 3),
            "Longest Streak label should be visible"
        )
    }
    
    func testStreakSubtitleShowsLetsGoWithNoHistory() {
        launchApp(practiceState: "empty")
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.staticTexts["Let's go!"].waitForExistence(timeout: 3),
            "Let's go! subtitle should appear when there is no practice history"
        )
    }
    
    func testCurrentStreakShowsCorrectDayCountForActiveStreak() {
        launchApp(practiceState: "streak_active")
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.staticTexts["2 days"].waitForExistence(timeout: 3),
            "Current streak should show 2 days for today + yesterday"
        )
    }
    
    // MARK: - Reminder banner
    
    func testReminderBannerAbsentWithNoHistory() {
        launchApp(practiceState: "empty")
        navigateToPracticeHistory()
        _ = app.staticTexts["Current Streak"].waitForExistence(timeout: 3)
        XCTAssertFalse(
            app.staticTexts["Practice today to keep your streak going!"].exists,
            "Reminder banner should not appear when there is no practice history"
        )
    }
    
    func testReminderBannerVisibleWhenStreakEndsYesterday() {
        launchApp(practiceState: "streak_yesterday")
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.staticTexts["Practice today to keep your streak going!"].waitForExistence(timeout: 3),
            "Reminder banner should appear when the active streak ends yesterday"
        )
    }
    
    func testReminderBannerAbsentWhenPracticedToday() {
        launchApp(practiceState: "streak_active")
        navigateToPracticeHistory()
        _ = app.staticTexts["Current Streak"].waitForExistence(timeout: 3)
        XCTAssertFalse(
            app.staticTexts["Practice today to keep your streak going!"].exists,
            "Reminder banner should not appear when the user has already practiced today"
        )
    }
    
    // MARK: - Practice list

    func testPracticeSectionAppearsForSelectedDate() {
        launchApp(practiceState: "empty")
        navigateToPracticeHistory()
        let noPractice = app.staticTexts["No practice recorded"]
        let hasPracticeList = app.tables.firstMatch
        let appeared = noPractice.waitForExistence(timeout: 3) || hasPracticeList.waitForExistence(timeout: 3)
        XCTAssertTrue(appeared, "A practice section should be displayed for the selected date")
    }

    func testNoPracticeRecordedTextAppearsForEmptyState() {
        launchApp(practiceState: "empty")
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.staticTexts["No practice recorded"].waitForExistence(timeout: 3),
            "No practice recorded should appear when no session exists for the selected date"
        )
    }

    // MARK: - Singular day display

    func testCurrentStreakShowsOneDayForYesterdayOnlyStreak() {
        launchApp(practiceState: "streak_yesterday")
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.staticTexts["1 day"].waitForExistence(timeout: 3),
            "Current streak should show '1 day' (singular) when streak is exactly one day"
        )
    }

    // MARK: - Five-day streak

    func testCurrentStreakShowsCorrectCountForFiveDayStreak() {
        launchApp(practiceState: "streak_5_days")
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.staticTexts["5 days"].waitForExistence(timeout: 3),
            "Current streak should show '5 days' for a five-day streak"
        )
    }

    // MARK: - Streak start date subtitle

    func testCurrentStreakSubtitleShowsSinceDateForActiveStreak() {
        launchApp(practiceState: "streak_active")
        navigateToPracticeHistory()
        let hasSinceLabel = app.staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH 'Since'"))
            .firstMatch
            .waitForExistence(timeout: 3)
        XCTAssertTrue(
            hasSinceLabel,
            "Current streak subtitle should show a 'Since [date]' label when there is an active streak"
        )
    }

    // MARK: - Share button

    func testShareButtonVisibleWithPracticeHistory() {
        launchApp(practiceState: "streak_5_days")
        navigateToPracticeHistory()
        XCTAssertTrue(
            app.buttons["Share"].waitForExistence(timeout: 3),
            "Share button should be visible in the navigation bar when there is practice history"
        )
    }
}
