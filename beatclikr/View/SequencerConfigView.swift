//
//  SequencerConfigView.swift
//  beatclikr
//
//  Created by Ben Funk on 6/13/26.
//

import SwiftUI

struct SequencerConfigView: View {
    @ObservedObject var viewModel: SequencerViewModel

    private let allInstruments = InstrumentLists.beat

    var body: some View {
        Form {
            Section("Tempo") {
                HStack {
                    Text("\(Int(viewModel.configuration.tempo)) BPM")
                        .frame(width: 80, alignment: .leading)
                    Slider(value: $viewModel.configuration.tempo, in: 40 ... 240, step: 1)
                        .onChange(of: viewModel.configuration.tempo) { _, _ in
                            viewModel.applyConfigurationChange()
                        }
                }
            }

            Section("Grid") {
                Stepper(
                    "Beats per Measure: \(viewModel.configuration.beatsPerMeasure)",
                    value: $viewModel.configuration.beatsPerMeasure, in: 1 ... 8,
                )
                .onChange(of: viewModel.configuration.beatsPerMeasure) { _, _ in
                    viewModel.applyConfigurationChange()
                }

                Stepper(
                    "Measures: \(viewModel.configuration.measuresCount)",
                    value: $viewModel.configuration.measuresCount, in: 1 ... 8,
                )
                .onChange(of: viewModel.configuration.measuresCount) { _, _ in
                    viewModel.applyConfigurationChange()
                }

                Stepper(
                    "Subdivisions: \(viewModel.configuration.subdivisionsPerBeat)",
                    value: $viewModel.configuration.subdivisionsPerBeat, in: 1 ... 4,
                )
                .onChange(of: viewModel.configuration.subdivisionsPerBeat) { _, _ in
                    viewModel.applyConfigurationChange()
                }
            }

            Section {
                ForEach(allInstruments, id: \.self) { instrument in
                    Toggle(instrument.description, isOn: instrumentBinding(instrument))
                }
            } header: {
                Text("Instruments (\(viewModel.selectedInstruments.count) of 4–8)")
            }
        }
        .navigationTitle("Configuration")
    }

    private func instrumentBinding(_ instrument: FileConstants) -> Binding<Bool> {
        Binding(
            get: { viewModel.selectedInstruments.contains(instrument) },
            set: { isOn in
                var instruments = viewModel.selectedInstruments
                if isOn, instruments.count < 8, !instruments.contains(instrument) {
                    instruments.append(instrument)
                    viewModel.updateSelectedInstruments(instruments)
                } else if !isOn, instruments.count > 4 {
                    instruments.removeAll { $0 == instrument }
                    viewModel.updateSelectedInstruments(instruments)
                }
            },
        )
    }
}
