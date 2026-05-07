//
//  MetronomeUITests.swift
//  beatclikrUITests
//
//  Created by Ben Funk on 5/7/26.
//

import XCTest

@MainActor
final class MetronomeUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment = ["UI_TESTING_METRONOME_RESET": "1"]
        app.launch()
    }

    override func tearDown() async throws {
        app = nil
    }

    // MARK: - Navigation

    private func navigateToMetronome() {
        // Metronome is the default tab, but tap it explicitly for reliability
        let tab = app.tabBars.buttons["Metronome"]
        if tab.waitForExistence(timeout: 2) {
            tab.tap()
        } else {
            // iPad sidebar
            app.buttons["Metronome"].tap()
        }
    }

    func testMetronomeTabExistsInTabBar() {
        XCTAssertTrue(
            app.tabBars.buttons["Metronome"].waitForExistence(timeout: 3),
            "Metronome tab should exist in the tab bar",
        )
    }

    func testBPMLabelVisibleOnMetronomeScreen() {
        navigateToMetronome()
        XCTAssertTrue(
            app.staticTexts["BPM"].waitForExistence(timeout: 3),
            "BPM label should be visible on the metronome screen",
        )
    }

    // MARK: - Play / Pause

    func testPlayButtonVisibleWhenStopped() {
        navigateToMetronome()
        XCTAssertTrue(
            app.buttons["Play"].waitForExistence(timeout: 3),
            "Play button should be visible when metronome is stopped",
        )
    }

    func testTappingPlayShowsPauseButton() {
        navigateToMetronome()
        app.buttons["Play"].firstMatch.tap()
        XCTAssertTrue(
            app.buttons["Pause"].waitForExistence(timeout: 3),
            "Pause button should appear after tapping Play",
        )
    }

    func testTappingPauseShowsPlayButton() {
        navigateToMetronome()
        app.buttons["Play"].firstMatch.tap()
        _ = app.buttons["Pause"].waitForExistence(timeout: 3)
        app.buttons["Pause"].tap()
        XCTAssertTrue(
            app.buttons["Play"].waitForExistence(timeout: 3),
            "Play button should reappear after tapping Pause",
        )
    }

    // MARK: - Tempo Ramp

    func testTempoRampToggleVisible() {
        navigateToMetronome()
        XCTAssertTrue(
            app.switches["Tempo Ramp"].waitForExistence(timeout: 3),
            "Tempo Ramp toggle should be visible on the metronome screen",
        )
    }

    func testTempoRampSuboptionsHiddenByDefault() {
        navigateToMetronome()
        _ = app.switches["Tempo Ramp"].waitForExistence(timeout: 3)
        XCTAssertFalse(
            app.staticTexts["Increase by"].exists,
            "Ramp suboptions should be hidden when Tempo Ramp is off",
        )
        XCTAssertFalse(
            app.staticTexts["Every"].exists,
            "Ramp interval control should be hidden when Tempo Ramp is off",
        )
    }

    func testEnablingTempoRampRevealsSuboptions() {
        navigateToMetronome()
        app.switches["Tempo Ramp"].tap()
        XCTAssertTrue(
            app.staticTexts["Increase by"].waitForExistence(timeout: 3),
            "'Increase by' control should appear when Tempo Ramp is enabled",
        )
        XCTAssertTrue(
            app.staticTexts["Every"].waitForExistence(timeout: 3),
            "'Every' control should appear when Tempo Ramp is enabled",
        )
    }

    func testDisablingTempoRampHidesSuboptions() {
        navigateToMetronome()
        let rampToggle = app.switches["Tempo Ramp"]
        rampToggle.tap() // enable
        _ = app.staticTexts["Increase by"].waitForExistence(timeout: 3)
        rampToggle.tap() // disable
        // Allow animation to complete
        let disappeared = app.staticTexts["Increase by"]
            .waitForNonExistence(timeout: 2)
        XCTAssertTrue(disappeared, "'Increase by' control should disappear when Tempo Ramp is disabled")
    }
}
