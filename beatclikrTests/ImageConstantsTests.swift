//
//  ImageConstantsTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 4/10/26.
//

import XCTest
@testable import beatclikr

final class ImageConstantsTests: XCTestCase {

    // MARK: - All constants are non-empty

    func testAllConstantsAreNonEmpty() {
        XCTAssertFalse(ImageConstants.beat.isEmpty)
        XCTAssertFalse(ImageConstants.rhythm.isEmpty)
        XCTAssertFalse(ImageConstants.tabInstant.isEmpty)
        XCTAssertFalse(ImageConstants.tabLibrary.isEmpty)
        XCTAssertFalse(ImageConstants.tabPlaylist.isEmpty)
        XCTAssertFalse(ImageConstants.tabSettings.isEmpty)
        XCTAssertFalse(ImageConstants.add.isEmpty)
        XCTAssertFalse(ImageConstants.subtract.isEmpty)
        XCTAssertFalse(ImageConstants.edit.isEmpty)
        XCTAssertFalse(ImageConstants.pause.isEmpty)
        XCTAssertFalse(ImageConstants.pauseFill.isEmpty)
        XCTAssertFalse(ImageConstants.play.isEmpty)
        XCTAssertFalse(ImageConstants.picker.isEmpty)
    }

    // MARK: - All constants are unique

    func testAllConstantsAreUnique() {
        let all = [
            ImageConstants.beat,
            ImageConstants.rhythm,
            ImageConstants.tabInstant,
            ImageConstants.tabLibrary,
            ImageConstants.tabPlaylist,
            ImageConstants.tabSettings,
            ImageConstants.add,
            ImageConstants.subtract,
            ImageConstants.edit,
            ImageConstants.pause,
            ImageConstants.pauseFill,
            ImageConstants.play,
            ImageConstants.picker,
        ]
        XCTAssertEqual(all.count, Set(all).count, "Every ImageConstants value should be unique")
    }

    // MARK: - Known values

    func testBeatAndRhythmIcons() {
        XCTAssertEqual(ImageConstants.beat, "diamond.fill")
        XCTAssertEqual(ImageConstants.rhythm, "circle.fill")
        XCTAssertNotEqual(ImageConstants.beat, ImageConstants.rhythm)
    }

    func testNavigationTabIcons() {
        XCTAssertEqual(ImageConstants.tabInstant, "metronome")
        XCTAssertEqual(ImageConstants.tabLibrary, "list.bullet.rectangle")
        XCTAssertEqual(ImageConstants.tabPlaylist, "music.note.list")
        XCTAssertEqual(ImageConstants.tabSettings, "gear")
    }

    func testActionIcons() {
        XCTAssertEqual(ImageConstants.add, "plus")
        XCTAssertEqual(ImageConstants.subtract, "minus")
        XCTAssertEqual(ImageConstants.edit, "square.and.pencil")
        XCTAssertEqual(ImageConstants.pause, "pause")
        XCTAssertEqual(ImageConstants.pauseFill, "pause.fill")
        XCTAssertEqual(ImageConstants.play, "play.fill")
        XCTAssertEqual(ImageConstants.picker, "chevron.up.chevron.down")
    }
}
