//
//  SettingsUITests.swift
//  beatclikrUITests
//
//  Created by Ben Funk on 5/4/26.
//

import XCTest

@MainActor
final class SettingsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app = nil
    }

    // Launches with a known clean notification state (resets defaults in the app on UI_TESTING_PRACTICE_STATE).
    private func launchApp(notificationState: String? = nil) {
        app.launchEnvironment["UI_TESTING_PRACTICE_STATE"] = "empty"
        if let state = notificationState {
            app.launchEnvironment["UI_TESTING_NOTIFICATION_STATE"] = state
        }
        app.launch()
    }

    private func navigateToSettings() {
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.waitForExistence(timeout: 2) {
            settingsTab.tap()
        } else {
            // iPad/Mac sidebar
            app.buttons["Settings"].tap()
        }
    }

    // MARK: - Basic navigation

    func testSettingsTabNavigationTitleIsVisible() {
        launchApp()
        navigateToSettings()
        XCTAssertTrue(
            app.navigationBars["Settings"].waitForExistence(timeout: 3),
            "Settings navigation bar title should be visible"
        )
    }

    // MARK: - No warnings when reminders are off

    func testNeitherWarningVisibleWhenRemindersOff() {
        launchApp()
        navigateToSettings()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)
        XCTAssertFalse(
            app.staticTexts["Reminders aren't enabled on this device."].exists,
            "Deferred warning should not appear when sendReminders is off"
        )
        XCTAssertFalse(
            app.staticTexts["Notifications are blocked on this device. You may still receive them on other devices."].exists,
            "Blocked warning should not appear when sendReminders is off"
        )
    }

    // MARK: - Deferred state
    //
    // The deferred warning ("Reminders aren't enabled on this device.") requires
    // UNAuthorizationStatus == .notDetermined. On a simulator where permissions were
    // previously granted, the app correctly detects .authorized at launch, calls
    // clearDeferral(), and shows no warning instead. That logic is covered in full
    // by SettingsViewModelTests (unit tests with a mock service).

    func testBlockedWarningAbsentInDeferredState() {
        // The blocked warning must never appear when the state was set up as deferred
        // (not denied), regardless of the simulator's actual permission status.
        launchApp(notificationState: "deferred")
        navigateToSettings()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)
        XCTAssertFalse(
            app.staticTexts["Notifications are blocked on this device. You may still receive them on other devices."].exists,
            "Blocked warning must not appear when notification state is deferred (not denied)"
        )
    }

    func testReminderTimePickerVisibleWhenSendRemindersOn() {
        // sendReminders is forced to true by the deferred launch setup.
        // Whether deferral is cleared (authorized) or kept (not-determined), the
        // toggle remains on and the date picker should be visible.
        launchApp(notificationState: "deferred")
        navigateToSettings()
        XCTAssertTrue(
            app.datePickers.firstMatch.waitForExistence(timeout: 5),
            "Reminder time picker should be visible when sendReminders is on"
        )
    }
}
