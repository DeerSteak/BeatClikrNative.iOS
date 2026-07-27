//
//  beatclikrTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 8/3/23.
//

@testable import BeatClikr
import SwiftData
import XCTest

// This file serves as the main test suite entry point.
// Individual test files:
// - MetronomeConstantsTests: Tests for all constants (BPM, timing, sizing, animation)
// - MetronomePlaybackViewModelTests: Tests for view model state management and callbacks
// - MetronomeTimingTests: Tests for timing calculations and precision
// - ImageConstantsTests: Tests for SF Symbols icon constants

final class beatclikrTests: XCTestCase {
    // Placeholder for integration tests if needed in the future
}

@MainActor
enum TestModelContainerFactory {
    static func make(_ modelTypes: [any PersistentModel.Type]) throws -> ModelContainer {
        let schema = Schema(modelTypes)
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none,
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

@MainActor
final class TestAudioPlaybackService: AudioPlaybackService {
    weak var metronomeDelegate: MetronomeAudioEngineDelegate?
    weak var polyrhythmDelegate: PolyrhythmAudioEngineDelegate?
    weak var lifecycleDelegate: AudioPlaybackLifecycleDelegate?

    var setupError: PlaybackError?
    var startError: PlaybackError?
    private(set) var metronomeStartCount = 0
    private(set) var polyrhythmStartCount = 0
    private(set) var metronomeStopCount = 0
    private(set) var polyrhythmStopCount = 0

    func setupMetronomeAudio(beatName _: String, rhythmName _: String) throws {
        if let setupError { throw setupError }
    }

    func setupPolyrhythmAudio(beatName _: String, rhythmName _: String) throws {
        if let setupError { throw setupError }
    }

    func setSoundBank(_: SoundBank) {}

    func startMetronome(bpm _: Double, subdivisions _: Int, accentPattern _: [Bool]?) throws {
        if let startError { throw startError }
        metronomeStartCount += 1
    }

    func stopMetronome() {
        metronomeStopCount += 1
    }

    func updateTempo(bpm _: Double, subdivisions _: Int) {}
    func setRamp(enabled _: Bool, increment _: Int, interval _: Int) {}

    func startPolyrhythm(bpm _: Double, beats _: Int, against _: Int) throws {
        if let startError { throw startError }
        polyrhythmStartCount += 1
    }

    func stopPolyrhythm() {
        polyrhythmStopCount += 1
    }

    func resetStopCounts() {
        metronomeStopCount = 0
        polyrhythmStopCount = 0
    }
}

@MainActor
final class TestLockScreenPlaybackController: LockScreenPlaybackControlling {
    private var stopHandler: (@MainActor () -> Void)?
    private(set) var startedModes: [PlaybackMode] = []
    private(set) var stopCount = 0

    func installStopHandler(_ handler: @escaping @MainActor () -> Void) {
        stopHandler = handler
    }

    func playbackStarted(mode: PlaybackMode) {
        startedModes.append(mode)
    }

    func playbackStopped() {
        stopCount += 1
    }

    func simulateStopCommand() {
        stopHandler?()
    }
}

@MainActor
final class PlaybackCoordinatorTests: XCTestCase {
    func testStopAllDoesNotPublishIdleStateWhenNothingIsPlaying() {
        let audio = TestAudioPlaybackService()
        let coordinator = PlaybackCoordinator(audio: audio)
        var metronomeNotifications = 0
        var polyrhythmNotifications = 0
        coordinator.onMetronomeStopped = { metronomeNotifications += 1 }
        coordinator.onPolyrhythmStopped = { polyrhythmNotifications += 1 }

        coordinator.stopAll()

        XCTAssertEqual(audio.metronomeStopCount, 0)
        XCTAssertEqual(audio.polyrhythmStopCount, 0)
        XCTAssertEqual(metronomeNotifications, 0)
        XCTAssertEqual(polyrhythmNotifications, 0)
    }

    func testStopAllStopsAndNotifiesOnlyTheActiveMode() throws {
        let audio = TestAudioPlaybackService()
        let coordinator = PlaybackCoordinator(audio: audio)
        var metronomeNotifications = 0
        var polyrhythmNotifications = 0
        coordinator.onMetronomeStopped = { metronomeNotifications += 1 }
        coordinator.onPolyrhythmStopped = { polyrhythmNotifications += 1 }
        try coordinator.startMetronome(bpm: 120, subdivisions: 1, accentPattern: nil)

        coordinator.stopAll()

        XCTAssertEqual(audio.metronomeStopCount, 1)
        XCTAssertEqual(audio.polyrhythmStopCount, 0)
        XCTAssertEqual(metronomeNotifications, 1)
        XCTAssertEqual(polyrhythmNotifications, 0)
    }

    func testLockScreenStopStopsActiveMetronomeAndNotifiesOwner() throws {
        let audio = TestAudioPlaybackService()
        let controls = TestLockScreenPlaybackController()
        let coordinator = PlaybackCoordinator(audio: audio, lockScreenControls: controls)
        var ownerWasStopped = false
        coordinator.onMetronomeStopped = { ownerWasStopped = true }

        try coordinator.startMetronome(bpm: 120, subdivisions: 1, accentPattern: nil)
        controls.simulateStopCommand()

        XCTAssertEqual(controls.startedModes, [.metronome])
        XCTAssertEqual(controls.stopCount, 1)
        XCTAssertEqual(audio.metronomeStopCount, 1)
        XCTAssertNil(coordinator.activeMode)
        XCTAssertTrue(ownerWasStopped)
    }

    func testLockScreenStopStopsActivePolyrhythmAndNotifiesOwner() throws {
        let audio = TestAudioPlaybackService()
        let controls = TestLockScreenPlaybackController()
        let coordinator = PlaybackCoordinator(audio: audio, lockScreenControls: controls)
        var ownerWasStopped = false
        coordinator.onPolyrhythmStopped = { ownerWasStopped = true }

        try coordinator.startPolyrhythm(bpm: 120, beats: 3, against: 4)
        controls.simulateStopCommand()

        XCTAssertEqual(controls.startedModes, [.polyrhythm])
        XCTAssertEqual(controls.stopCount, 1)
        XCTAssertEqual(audio.polyrhythmStopCount, 1)
        XCTAssertNil(coordinator.activeMode)
        XCTAssertTrue(ownerWasStopped)
    }

    func testInterruptionClearsMetronomeWithoutAutomaticResume() throws {
        let audio = TestAudioPlaybackService()
        let coordinator = PlaybackCoordinator(audio: audio)
        var interrupted = false
        coordinator.onMetronomeInterrupted = { interrupted = true }

        try coordinator.startMetronome(bpm: 120, subdivisions: 1, accentPattern: nil)
        audio.lifecycleDelegate?.audioPlaybackWasInterrupted()

        XCTAssertNil(coordinator.activeMode)
        XCTAssertTrue(interrupted)
        XCTAssertEqual(audio.metronomeStartCount, 1)
    }

    func testInterruptionClearsPolyrhythmWithoutAutomaticResume() throws {
        let audio = TestAudioPlaybackService()
        let coordinator = PlaybackCoordinator(audio: audio)
        var interrupted = false
        coordinator.onPolyrhythmInterrupted = { interrupted = true }

        try coordinator.startPolyrhythm(bpm: 120, beats: 3, against: 4)
        audio.lifecycleDelegate?.audioPlaybackWasInterrupted()

        XCTAssertNil(coordinator.activeMode)
        XCTAssertTrue(interrupted)
        XCTAssertEqual(audio.polyrhythmStartCount, 1)
    }

    func testStartingPolyrhythmDisplacesMetronome() throws {
        let audio = TestAudioPlaybackService()
        let coordinator = PlaybackCoordinator(audio: audio)
        var metronomeWasStopped = false
        coordinator.onMetronomeStopped = { metronomeWasStopped = true }

        try coordinator.startMetronome(bpm: 120, subdivisions: 1, accentPattern: nil)
        try coordinator.startPolyrhythm(bpm: 120, beats: 3, against: 2)

        XCTAssertEqual(coordinator.activeMode, .polyrhythm)
        XCTAssertEqual(audio.metronomeStopCount, 1)
        XCTAssertTrue(metronomeWasStopped)
    }

    func testStartingMetronomeDisplacesPolyrhythm() throws {
        let audio = TestAudioPlaybackService()
        let coordinator = PlaybackCoordinator(audio: audio)
        var polyrhythmWasStopped = false
        coordinator.onPolyrhythmStopped = { polyrhythmWasStopped = true }

        try coordinator.startPolyrhythm(bpm: 120, beats: 3, against: 2)
        try coordinator.startMetronome(bpm: 120, subdivisions: 1, accentPattern: nil)

        XCTAssertEqual(coordinator.activeMode, .metronome)
        XCTAssertEqual(audio.polyrhythmStopCount, 1)
        XCTAssertTrue(polyrhythmWasStopped)
    }

    func testViewModelsCannotRemainPlayingTogether() {
        let audio = TestAudioPlaybackService()
        let coordinator = PlaybackCoordinator(audio: audio)
        let settings = SettingsViewModel()
        let metronome = MetronomePlaybackViewModel(audio: coordinator, settings: settings)
        let polyrhythm = PolyrhythmViewModel(audio: coordinator, settings: settings)
        coordinator.onMetronomeStopped = { [weak metronome] in
            metronome?.playbackWasStoppedByCoordinator()
        }
        coordinator.onPolyrhythmStopped = { [weak polyrhythm] in
            polyrhythm?.playbackWasStoppedByCoordinator()
        }

        metronome.start()
        polyrhythm.start()

        XCTAssertFalse(metronome.isPlaying)
        XCTAssertTrue(polyrhythm.isPlaying)
        XCTAssertEqual(coordinator.activeMode, .polyrhythm)
    }

    func testFailedReplacementLeavesNoActiveMode() throws {
        let audio = TestAudioPlaybackService()
        let coordinator = PlaybackCoordinator(audio: audio)
        try coordinator.startMetronome(bpm: 120, subdivisions: 1, accentPattern: nil)
        audio.startError = .engineStartFailed

        XCTAssertThrowsError(try coordinator.startPolyrhythm(bpm: 120, beats: 3, against: 2))
        XCTAssertNil(coordinator.activeMode)
    }
}
