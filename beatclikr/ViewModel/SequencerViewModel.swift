//
//  SequencerViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 6/10/26.
//

import Combine
import SwiftData
import SwiftUI

@MainActor
final class SequencerViewModel: ObservableObject {
    @Published var configuration: SequencerConfiguration = .init()
    @Published var pattern: SequencePattern
    @Published var selectedInstruments: [FileConstants] = []
    @Published var isPlaying: Bool = false
    @Published var currentStep: Int = 0
    @Published var currentMeasure: Int = 0
    @Published var currentBeat: Int = 0
    @Published var savedSequences: [SavedSequence] = []

    private let audioService = AudioPlayerService.instance
    private var configDebounceTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Default to 8 most common instruments
        let defaultInstruments: [FileConstants] = [
            .Kick, .Snare, .HatClosed, .HatOpen,
            .TomHi, .TomMid, .TomLo, .CrashL,
        ]
        selectedInstruments = defaultInstruments

        let initialConfig = SequencerConfiguration()
        pattern = SequencePattern(
            instruments: Array(defaultInstruments).sorted { $0.rawValue < $1.rawValue },
            config: initialConfig,
        )

        audioService.sequencerDelegate = self
    }

    // MARK: - Pattern Control

    func toggleCell(instrument: FileConstants, step: Int) {
        pattern.toggle(instrument: instrument, at: step)

        if isPlaying {
            let patternCopy = pattern // Struct copy for thread safety
            audioService.updateSequencerPattern(patternCopy)
        }
    }

    // MARK: - Playback Control

    func play() {
        isPlaying = true
        audioService.startSequencer(pattern: pattern)
    }

    func stop() {
        isPlaying = false
        audioService.stopSequencer()
        currentStep = 0
        currentMeasure = 0
        currentBeat = 0
    }

    // MARK: - Configuration (Debounced)

    func updateTempo(_ bpm: Double) {
        configuration.tempo = bpm
        applyConfigurationChangeDebounced()
    }

    func updateBeatsPerMeasure(_ beats: Int) {
        configuration.beatsPerMeasure = beats
        applyConfigurationChangeDebounced()
    }

    func updateMeasuresCount(_ measures: Int) {
        configuration.measuresCount = measures
        applyConfigurationChangeDebounced()
    }

    func updateSubdivisionsPerBeat(_ subdivisions: Int) {
        configuration.subdivisionsPerBeat = subdivisions
        applyConfigurationChangeDebounced()
    }

    private func applyConfigurationChangeDebounced() {
        configDebounceTask?.cancel()
        configDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            applyConfigurationChange()
        }
    }

    func applyConfigurationChange() {
        pattern.updateConfig(configuration)

        if isPlaying {
            audioService.updateSequencerPattern(pattern)
            audioService.updateSequencerTempo(configuration.tempo)
        }
    }

    // MARK: - Instrument Selection

    func updateSelectedInstruments(_ instruments: [FileConstants]) {
        guard instruments.count >= 4, instruments.count <= 8 else { return }

        let oldPattern = pattern
        selectedInstruments = instruments

        pattern = SequencePattern(
            instruments: Array(selectedInstruments).sorted { $0.rawValue < $1.rawValue },
            config: configuration,
        )

        // Preserve existing data for instruments that remain selected
        for instrument in selectedInstruments {
            for step in 0 ..< configuration.totalSteps {
                if oldPattern.isActive(instrument: instrument, at: step) {
                    pattern.toggle(instrument: instrument, at: step)
                }
            }
        }

        if isPlaying {
            audioService.stopSequencer()
            audioService.startSequencer(pattern: pattern)
        }
    }

    // MARK: - CloudKit Save/Load

    func saveSequence(name: String, context: ModelContext) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SequencerError.emptyName
        }

        let patternData = try pattern.encode()
        let sequence = SavedSequence(
            name: name,
            tempo: configuration.tempo,
            beatsPerMeasure: configuration.beatsPerMeasure,
            measuresCount: configuration.measuresCount,
            subdivisionsPerBeat: configuration.subdivisionsPerBeat,
            patternData: patternData,
        )

        context.insert(sequence)
        try context.save()
        fetchSavedSequences(context: context)
    }

    func loadSequence(_ sequence: SavedSequence) {
        configuration = SequencerConfiguration(
            tempo: sequence.tempo ?? 120.0,
            beatsPerMeasure: sequence.beatsPerMeasure ?? 4,
            measuresCount: sequence.measuresCount ?? 4,
            subdivisionsPerBeat: sequence.subdivisionsPerBeat ?? 4,
        )

        if let patternData = sequence.patternData {
            do {
                pattern = try SequencePattern.decode(
                    patternData,
                    instruments: Array(selectedInstruments).sorted { $0.rawValue < $1.rawValue },
                    config: configuration,
                )
            } catch {
                print("Failed to decode sequence: \(error)")
            }
        }

        if isPlaying {
            audioService.stopSequencer()
            audioService.startSequencer(pattern: pattern)
        }
    }

    func fetchSavedSequences(context: ModelContext) {
        let descriptor = FetchDescriptor<SavedSequence>(
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)],
        )
        savedSequences = (try? context.fetch(descriptor)) ?? []
    }

    func deleteSequence(_ sequence: SavedSequence, context: ModelContext) {
        context.delete(sequence)
        try? context.save()
        fetchSavedSequences(context: context)
    }
}

// MARK: - SequencerAudioEngineDelegate

extension SequencerViewModel: SequencerAudioEngineDelegate {
    func sequencerStepFired(step: Int, measure: Int, beat: Int) {
        currentStep = step
        currentMeasure = measure
        currentBeat = beat
    }
}

enum SequencerError: Error {
    case emptyName
}
