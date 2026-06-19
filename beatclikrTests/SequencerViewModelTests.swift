//
//  SequencerViewModelTests.swift
//  beatclikrTests
//

@testable import BeatClikr
import Foundation
import SwiftData
import Testing

@MainActor
struct SequencerViewModelTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: SavedSequence.self, configurations: config)
    }

    // MARK: - Initial state

    @Test func `initial selected instruments count is 8`() {
        #expect(SequencerViewModel().selectedInstruments.count == 8)
    }

    @Test func `initial pattern matches default instruments and config`() {
        let vm = SequencerViewModel()
        for instrument in vm.selectedInstruments {
            #expect(!vm.pattern.isActive(instrument: instrument, at: 0))
        }
    }

    @Test func `initial isPlaying is false`() {
        #expect(SequencerViewModel().isPlaying == false)
    }

    @Test func `initial currentStep is 0`() {
        #expect(SequencerViewModel().currentStep == 0)
    }

    // MARK: - toggleCell

    @Test func `toggle cell activates a step`() {
        let vm = SequencerViewModel()
        let instrument = vm.selectedInstruments[0]
        vm.toggleCell(instrument: instrument, step: 0)
        #expect(vm.pattern.isActive(instrument: instrument, at: 0))
    }

    @Test func `toggle cell twice deactivates a step`() {
        let vm = SequencerViewModel()
        let instrument = vm.selectedInstruments[0]
        vm.toggleCell(instrument: instrument, step: 0)
        vm.toggleCell(instrument: instrument, step: 0)
        #expect(!vm.pattern.isActive(instrument: instrument, at: 0))
    }

    @Test func `toggle cell does not affect other instruments`() {
        let vm = SequencerViewModel()
        vm.toggleCell(instrument: vm.selectedInstruments[0], step: 0)
        #expect(!vm.pattern.isActive(instrument: vm.selectedInstruments[1], at: 0))
    }

    // MARK: - play / stop

    @Test func `play sets isPlaying to true`() {
        let vm = SequencerViewModel()
        vm.play()
        #expect(vm.isPlaying)
    }

    @Test func `stop sets isPlaying to false`() {
        let vm = SequencerViewModel()
        vm.play()
        vm.stop()
        #expect(!vm.isPlaying)
    }

    @Test func `stop resets currentStep to 0`() {
        let vm = SequencerViewModel()
        vm.play()
        vm.stop()
        #expect(vm.currentStep == 0)
    }

    // MARK: - applyConfigurationChange

    @Test func `apply configuration change updates pattern total steps`() {
        let vm = SequencerViewModel()
        vm.configuration.measuresCount = 2
        vm.applyConfigurationChange()
        #expect(vm.pattern.config.totalSteps == vm.configuration.totalSteps)
    }

    @Test func `apply configuration change preserves active cells within new bounds`() {
        let vm = SequencerViewModel()
        let instrument = vm.selectedInstruments[0]
        vm.toggleCell(instrument: instrument, step: 0)
        vm.configuration.measuresCount = 2
        vm.applyConfigurationChange()
        #expect(vm.pattern.isActive(instrument: instrument, at: 0))
    }

    // MARK: - updateSelectedInstruments

    @Test func `update selected instruments below minimum is rejected`() {
        let vm = SequencerViewModel()
        let original = vm.selectedInstruments
        vm.updateSelectedInstruments(Array(original.prefix(3)))
        #expect(vm.selectedInstruments.count == original.count)
    }

    @Test func `update selected instruments above maximum is rejected`() {
        let vm = SequencerViewModel()
        let tooMany = Array(InstrumentLists.beat.prefix(9))
        guard tooMany.count > 8 else { return }
        vm.updateSelectedInstruments(tooMany)
        #expect(vm.selectedInstruments.count <= 8)
    }

    @Test func `update selected instruments with valid count is accepted`() {
        let vm = SequencerViewModel()
        let newInstruments = Array(InstrumentLists.beat.prefix(4))
        vm.updateSelectedInstruments(newInstruments)
        #expect(vm.selectedInstruments.count == 4)
    }

    @Test func `update selected instruments preserves pattern data for retained instruments`() {
        let vm = SequencerViewModel()
        let instrument = vm.selectedInstruments[0]
        vm.toggleCell(instrument: instrument, step: 0)

        let newInstruments = Array(vm.selectedInstruments.prefix(6))
        vm.updateSelectedInstruments(newInstruments)

        if vm.selectedInstruments.contains(instrument) {
            #expect(vm.pattern.isActive(instrument: instrument, at: 0))
        }
    }

    // MARK: - saveSequence

    @Test func `save sequence with empty name throws`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = SequencerViewModel()
        #expect(throws: SequencerError.emptyName) {
            try vm.saveSequence(name: "", context: context)
        }
    }

    @Test func `save sequence with whitespace-only name throws`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = SequencerViewModel()
        #expect(throws: SequencerError.emptyName) {
            try vm.saveSequence(name: "   ", context: context)
        }
    }

    @Test func `save sequence persists to context`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = SequencerViewModel()
        try vm.saveSequence(name: "Test", context: context)
        let fetched = try context.fetch(FetchDescriptor<SavedSequence>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Test")
    }

    @Test func `save sequence stores current tempo`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = SequencerViewModel()
        vm.configuration.tempo = 140
        try vm.saveSequence(name: "Test", context: context)
        let fetched = try context.fetch(FetchDescriptor<SavedSequence>())
        #expect(fetched.first?.tempo == 140)
    }

    @Test func `save sequence updates savedSequences`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = SequencerViewModel()
        try vm.saveSequence(name: "Test", context: context)
        #expect(vm.savedSequences.count == 1)
    }

    // MARK: - loadSequence

    @Test func `load sequence restores tempo`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = SequencerViewModel()
        vm.configuration.tempo = 180
        try vm.saveSequence(name: "Fast", context: context)

        let vm2 = SequencerViewModel()
        vm2.loadSequence(vm.savedSequences[0], context: context)
        #expect(vm2.configuration.tempo == 180)
    }

    @Test func `load sequence restores beats per measure`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = SequencerViewModel()
        vm.configuration.beatsPerMeasure = 3
        vm.applyConfigurationChange()
        try vm.saveSequence(name: "Waltz", context: context)

        let vm2 = SequencerViewModel()
        vm2.loadSequence(vm.savedSequences[0], context: context)
        #expect(vm2.configuration.beatsPerMeasure == 3)
    }

    @Test func `load sequence stops playback`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = SequencerViewModel()
        try vm.saveSequence(name: "Test", context: context)
        vm.play()
        vm.loadSequence(vm.savedSequences[0], context: context)
        #expect(!vm.isPlaying)
    }

    // MARK: - deleteSequence

    @Test func `delete sequence removes from context`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = SequencerViewModel()
        try vm.saveSequence(name: "Test", context: context)
        let sequence = vm.savedSequences[0]
        vm.deleteSequence(sequence, context: context)
        let fetched = try context.fetch(FetchDescriptor<SavedSequence>())
        #expect(fetched.isEmpty)
    }

    @Test func `delete sequence updates savedSequences`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = SequencerViewModel()
        try vm.saveSequence(name: "A", context: context)
        try vm.saveSequence(name: "B", context: context)
        let toDelete = vm.savedSequences[0]
        vm.deleteSequence(toDelete, context: context)
        #expect(vm.savedSequences.count == 1)
    }

    // MARK: - fetchSavedSequences

    @Test func `fetch saved sequences returns empty when none saved`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = SequencerViewModel()
        vm.fetchSavedSequences(context: context)
        #expect(vm.savedSequences.isEmpty)
    }

    @Test func `fetch saved sequences returns all saved`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = SequencerViewModel()
        try vm.saveSequence(name: "A", context: context)
        try vm.saveSequence(name: "B", context: context)
        vm.fetchSavedSequences(context: context)
        #expect(vm.savedSequences.count == 2)
    }
}
