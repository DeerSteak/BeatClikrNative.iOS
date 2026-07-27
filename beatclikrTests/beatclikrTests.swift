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

    var setupError: PlaybackError?
    var startError: PlaybackError?
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
    }

    func stopMetronome() {
        metronomeStopCount += 1
    }

    func updateTempo(bpm _: Double, subdivisions _: Int) {}
    func setRamp(enabled _: Bool, increment _: Int, interval _: Int) {}

    func startPolyrhythm(bpm _: Double, beats _: Int, against _: Int) throws {
        if let startError { throw startError }
    }

    func stopPolyrhythm() {
        polyrhythmStopCount += 1
    }

    func resetStopCounts() {
        metronomeStopCount = 0
        polyrhythmStopCount = 0
    }
}
