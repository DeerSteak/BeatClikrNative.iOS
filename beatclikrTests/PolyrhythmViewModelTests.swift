//
//  PolyrhythmViewModelTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 5/7/26.
//

@testable import BeatClikr
import XCTest

@MainActor
final class PolyrhythmViewModelTests: XCTestCase {
    var viewModel: PolyrhythmViewModel!

    override func setUp() async throws {
        viewModel = PolyrhythmViewModel()
    }

    override func tearDown() async throws {
        viewModel.stop()
        viewModel = nil
    }

    // MARK: - Initial State

    func testInitialPlaybackState() {
        XCTAssertFalse(viewModel.isPlaying, "Should not be playing initially")
    }

    func testInitialPulseValues() {
        XCTAssertEqual(viewModel.beatPulse, 0, "Beat pulse should start at 0")
        XCTAssertEqual(viewModel.rhythmPulse, 0, "Rhythm pulse should start at 0")
    }

    func testInitialActiveIndexes() {
        XCTAssertEqual(viewModel.activeBeatIndex, 0, "Active beat index should start at 0")
        XCTAssertEqual(viewModel.activeRhythmIndex, 0, "Active rhythm index should start at 0")
    }

    func testInitialCycleProgress() {
        XCTAssertEqual(viewModel.cycleProgress, 0, "Cycle progress should start at 0")
    }

    // MARK: - Playback Control

    func testToggleStartsPlayback() {
        viewModel.togglePlayPause()
        XCTAssertTrue(viewModel.isPlaying, "Should be playing after first toggle")
    }

    func testToggleTwiceStopsPlayback() {
        viewModel.togglePlayPause()
        viewModel.togglePlayPause()
        XCTAssertFalse(viewModel.isPlaying, "Should not be playing after toggling off")
    }

    func testStopSetsPlayingToFalse() {
        viewModel.start()
        XCTAssertTrue(viewModel.isPlaying, "Should be playing after start")
        viewModel.stop()
        XCTAssertFalse(viewModel.isPlaying, "Should not be playing after stop")
    }

    func testStopResetsCycleProgressToZero() {
        viewModel.cycleProgress = 0.75
        viewModel.stop()
        XCTAssertEqual(viewModel.cycleProgress, 0, "Cycle progress should reset to 0 on stop")
    }

    func testStartAdvancesPlayheadResetID() {
        let initialID = viewModel.playheadResetID
        viewModel.start()
        XCTAssertEqual(viewModel.playheadResetID, initialID + 1, "Starting playback should force a fresh playhead identity")
    }

    func testChangingCountsWhilePlayingAdvancesPlayheadResetID() {
        viewModel.start()
        let playingID = viewModel.playheadResetID
        viewModel.beats += 1
        XCTAssertEqual(viewModel.playheadResetID, playingID + 1, "Restarting after count changes should force a fresh playhead identity")
    }

    // MARK: - Delegate: Active Index Updates

    func testBeatFiredUpdatesBeatIndex() {
        viewModel.polyrhythmBeatFired(beatFired: true, rhythmFired: false, beatIndex: 2, rhythmIndex: 0)
        XCTAssertEqual(viewModel.activeBeatIndex, 2, "activeBeatIndex should update when beat fires")
    }

    func testRhythmFiredUpdatesRhythmIndex() {
        viewModel.polyrhythmBeatFired(beatFired: false, rhythmFired: true, beatIndex: 0, rhythmIndex: 3)
        XCTAssertEqual(viewModel.activeRhythmIndex, 3, "activeRhythmIndex should update when rhythm fires")
    }

    func testBeatOnlyDoesNotChangeRhythmIndex() {
        viewModel.activeRhythmIndex = 2
        viewModel.polyrhythmBeatFired(beatFired: true, rhythmFired: false, beatIndex: 1, rhythmIndex: 0)
        XCTAssertEqual(viewModel.activeRhythmIndex, 2, "Rhythm index should not change when only beat fires")
    }

    func testRhythmOnlyDoesNotChangeBeatIndex() {
        viewModel.activeBeatIndex = 3
        viewModel.polyrhythmBeatFired(beatFired: false, rhythmFired: true, beatIndex: 0, rhythmIndex: 1)
        XCTAssertEqual(viewModel.activeBeatIndex, 3, "Beat index should not change when only rhythm fires")
    }

    func testBothFiredUpdatesBothIndexes() {
        viewModel.polyrhythmBeatFired(beatFired: true, rhythmFired: true, beatIndex: 1, rhythmIndex: 2)
        XCTAssertEqual(viewModel.activeBeatIndex, 1)
        XCTAssertEqual(viewModel.activeRhythmIndex, 2)
    }

    func testNeitherFiredChangesNoIndexes() {
        viewModel.activeBeatIndex = 2
        viewModel.activeRhythmIndex = 3
        viewModel.polyrhythmBeatFired(beatFired: false, rhythmFired: false, beatIndex: 5, rhythmIndex: 5)
        XCTAssertEqual(viewModel.activeBeatIndex, 2, "Beat index should not change when nothing fires")
        XCTAssertEqual(viewModel.activeRhythmIndex, 3, "Rhythm index should not change when nothing fires")
    }

    // MARK: - Timing Math

    func testCycleDurationFormula() {
        // cycleDuration = Double(against) * (60.0 / bpm)
        // At 120 BPM with 4 beats against: 4 * 0.5 = 2.0s
        let bpm = 120.0
        let against = 4
        let cycleDuration = Double(against) * (60.0 / bpm)
        XCTAssertEqual(cycleDuration, 2.0, accuracy: 0.001, "Cycle duration should be 2 seconds at 120 BPM over 4 beats")
    }

    func testRhythmIntervalFormula() {
        // rhythmInterval = Double(against) * (60.0 / bpm) / Double(beats)
        // 3-against-2 at 120 BPM: 3 * 0.5 / 2 = 0.75s per rhythm note
        let bpm = 120.0
        let beats = 2
        let against = 3
        let interval = Double(against) * (60.0 / bpm) / Double(beats)
        XCTAssertEqual(interval, 0.75, accuracy: 0.001, "Rhythm interval should be 0.75s for 3:2 at 120 BPM")
    }

    func testRhythmIntervalForCommon4Against3() {
        // 4-against-3 at 60 BPM: 4 * 1.0 / 3 ≈ 1.333s per rhythm note
        let bpm = 60.0
        let beats = 3
        let against = 4
        let interval = Double(against) * (60.0 / bpm) / Double(beats)
        XCTAssertEqual(interval, 4.0 / 3.0, accuracy: 0.001, "Rhythm interval should be 4/3 seconds for 4:3 at 60 BPM")
    }
}
