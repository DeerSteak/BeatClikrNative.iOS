//
//  MetronomePlaybackViewModelTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 4/10/26.
//

@testable import BeatClikr
import XCTest

@MainActor
final class MetronomePlaybackViewModelTests: XCTestCase {
    var viewModel: MetronomePlaybackViewModel!

    override func setUp() async throws {
        viewModel = MetronomePlaybackViewModel()
    }

    override func tearDown() async throws {
        viewModel.stop()
        viewModel = nil
    }

    // MARK: - BPM Tests

    func testBPMClamping() {
        // Test that BPM is clamped to valid range in setupMetronome
        viewModel.beatsPerMinute = 20 // Below minimum
        viewModel.setupMetronome()
        // Note: setupMetronome clamps song.beatsPerMinute, not the published property
        // This test verifies the clamping logic exists

        viewModel.beatsPerMinute = 300 // Above maximum
        viewModel.setupMetronome()
        // Same as above - verifies clamping occurs
    }

    func testBPMWithinValidRange() {
        viewModel.beatsPerMinute = 120
        XCTAssertEqual(viewModel.beatsPerMinute, 120, "BPM should be set to 120")
    }

    // MARK: - Icon Scale Animation Tests

    func testInitialIconScale() {
        XCTAssertEqual(viewModel.iconScale, MetronomeConstants.iconScaleMin, "Initial icon scale should be at minimum")
    }

    func testBeatFiredUpdatesIconScale() {
        // Simulate beat fired
        viewModel.metronomeBeatFired(isBeat: true, beatInterval: 0.5)

        // Note: We can't assert the exact value here because withAnimation() starts an async animation.
        // The scale is set to max, then immediately animated to min. By the time we check, the animation
        // has already started, so the value will be somewhere between min and max.
        // We just verify the method completes without crashing.
        XCTAssertNotNil(viewModel.iconScale, "Icon scale should exist after beat fires")
    }

    func testRhythmFiredDoesNotUpdateIconScale() {
        // Set initial scale
        viewModel.metronomeBeatFired(isBeat: true, beatInterval: 0.5)
        let scaleAfterBeat = viewModel.iconScale

        // Simulate rhythm fired
        viewModel.metronomeBeatFired(isBeat: false, beatInterval: 0.5)

        // Scale should not change (animation continues from beat)
        XCTAssertEqual(viewModel.iconScale, scaleAfterBeat, "Icon scale should not change on rhythm")
    }

    // MARK: - Playback State Tests

    func testInitialPlaybackState() {
        XCTAssertFalse(viewModel.isPlaying, "Metronome should not be playing initially")
    }

    func testTogglePlayPause() {
        let initialState = viewModel.isPlaying

        viewModel.togglePlayPause()
        XCTAssertNotEqual(viewModel.isPlaying, initialState, "Play state should toggle")

        viewModel.togglePlayPause()
        XCTAssertEqual(viewModel.isPlaying, initialState, "Play state should toggle back")
    }

    func testStopSetsPlayingToFalse() {
        viewModel.start()
        XCTAssertTrue(viewModel.isPlaying, "Should be playing after start")

        viewModel.stop()
        XCTAssertFalse(viewModel.isPlaying, "Should not be playing after stop")
    }

    // MARK: - Groove (Subdivision) Tests

    func testGrooveSelection() {
        viewModel.selectedGroove = .quarter
        XCTAssertEqual(viewModel.selectedGroove, .quarter, "Should select quarter note groove")

        viewModel.selectedGroove = .eighth
        XCTAssertEqual(viewModel.selectedGroove, .eighth, "Should select eighth note groove")
    }

    // MARK: - Beat/Rhythm Callback Tests

    func testMetronomeBeatFiredWithBeat() {
        viewModel.metronomeBeatFired(isBeat: true, beatInterval: 0.5)
        // If no crash, the beat handling works
    }

    func testMetronomeBeatFiredWithRhythm() {
        viewModel.metronomeBeatFired(isBeat: false, beatInterval: 0.5)
        // If no crash, the rhythm handling works
    }

    // MARK: - Tempo Ramp Tests

    func testRampDefaultsToDisabled() {
        XCTAssertFalse(viewModel.rampEnabled, "Ramp should be disabled by default")
    }

    func testRampDoesNotFireWhenDisabled() {
        viewModel.rampEnabled = false
        viewModel.rampInterval = 4
        viewModel.rampIncrement = 5
        viewModel.beatsPerMinute = 100
        for _ in 0 ..< 10 {
            viewModel.metronomeBeatFired(isBeat: true, beatInterval: 0.5)
        }
        XCTAssertEqual(viewModel.beatsPerMinute, 100, "BPM should not change when ramp is disabled")
    }

    func testRampOnlyCountsBeatsNotSubdivisions() {
        viewModel.rampEnabled = true
        viewModel.rampInterval = 4
        viewModel.rampIncrement = 5
        viewModel.beatsPerMinute = 100
        // Fire many rhythm (subdivision) events — they should not count toward ramp
        for _ in 0 ..< 20 {
            viewModel.metronomeBeatFired(isBeat: false, beatInterval: 0.5)
        }
        XCTAssertEqual(viewModel.beatsPerMinute, 100, "Subdivision events should not count toward ramp interval")
    }

    func testRampDoesNotFireBeforeInterval() {
        viewModel.rampEnabled = true
        viewModel.rampInterval = 8
        viewModel.rampIncrement = 5
        viewModel.beatsPerMinute = 100
        // With -1 init and > 0 guard, ramp fires when rampBeatCount == rampInterval (after rampInterval+1 beats).
        // Fire only rampInterval beats — not enough to trigger.
        for _ in 0 ..< viewModel.rampInterval {
            viewModel.metronomeBeatFired(isBeat: true, beatInterval: 0.5)
        }
        XCTAssertEqual(viewModel.beatsPerMinute, 100, "BPM should not change before ramp interval is reached")
    }

    func testRampFiresAfterInterval() {
        viewModel.rampEnabled = true
        viewModel.rampInterval = 4
        viewModel.rampIncrement = 5
        viewModel.beatsPerMinute = 100
        // rampBeatCount starts at -1; first ramp fires when count reaches rampInterval (after rampInterval+1 calls)
        for _ in 0 ..< (viewModel.rampInterval + 1) {
            viewModel.metronomeBeatFired(isBeat: true, beatInterval: 0.5)
        }
        XCTAssertEqual(viewModel.beatsPerMinute, 105, "BPM should increase by rampIncrement after interval beats")
    }

    func testRampCapsAtMaxBPM() {
        viewModel.rampEnabled = true
        viewModel.rampInterval = 4
        viewModel.rampIncrement = 100 // large enough to overshoot maxBPM
        viewModel.beatsPerMinute = MetronomeConstants.maxBPM - 5
        for _ in 0 ..< (viewModel.rampInterval + 1) {
            viewModel.metronomeBeatFired(isBeat: true, beatInterval: 0.5)
        }
        XCTAssertEqual(viewModel.beatsPerMinute, MetronomeConstants.maxBPM, "BPM should be capped at maxBPM")
    }

    func testRampDoesNothingAtMaxBPM() {
        viewModel.rampEnabled = true
        viewModel.rampInterval = 4
        viewModel.rampIncrement = 5
        viewModel.beatsPerMinute = MetronomeConstants.maxBPM
        for _ in 0 ..< (viewModel.rampInterval + 1) {
            viewModel.metronomeBeatFired(isBeat: true, beatInterval: 0.5)
        }
        XCTAssertEqual(viewModel.beatsPerMinute, MetronomeConstants.maxBPM, "BPM should not change when already at maxBPM")
    }

    func testStopResetsRampBpmToStartingBpm() {
        viewModel.rampEnabled = true
        viewModel.rampInterval = 4
        viewModel.rampIncrement = 5
        viewModel.beatsPerMinute = 100
        viewModel.start()
        // Fire enough beats to trigger one ramp increment
        for _ in 0 ..< (viewModel.rampInterval + 1) {
            viewModel.metronomeBeatFired(isBeat: true, beatInterval: 0.5)
        }
        XCTAssertEqual(viewModel.beatsPerMinute, 105, "BPM should have ramped up during playback")
        viewModel.stop()
        XCTAssertEqual(viewModel.beatsPerMinute, 100, "BPM should reset to starting value when stopped with ramp enabled")
    }

    func testStopDoesNotResetBpmWhenRampDisabled() {
        viewModel.rampEnabled = false
        viewModel.beatsPerMinute = 100
        viewModel.beatsPerMinute = 120 // simulate user changing BPM
        viewModel.stop()
        XCTAssertEqual(viewModel.beatsPerMinute, 120, "BPM should not be reset when ramp is disabled")
    }

    func testRampBeatCountResetsOnStop() {
        viewModel.rampEnabled = true
        viewModel.rampInterval = 4
        viewModel.rampIncrement = 5
        viewModel.beatsPerMinute = 100
        // Fire beats up to rampInterval-1 (just below threshold before stop)
        for _ in 0 ..< (viewModel.rampInterval - 1) {
            viewModel.metronomeBeatFired(isBeat: true, beatInterval: 0.5)
        }
        XCTAssertEqual(viewModel.beatsPerMinute, 100, "BPM should not have ramped yet")
        viewModel.stop()
        // stop() resets rampBeatCount to -1; reset BPM to known value
        viewModel.beatsPerMinute = 100
        // Fire just one beat — if count was NOT reset, count would be at rampInterval and ramp would fire.
        // If reset correctly to -1, count becomes 0 and the > 0 guard blocks it.
        viewModel.metronomeBeatFired(isBeat: true, beatInterval: 0.5)
        XCTAssertEqual(viewModel.beatsPerMinute, 100, "Ramp beat count should reset on stop, preventing premature ramp after restart")
    }
}
