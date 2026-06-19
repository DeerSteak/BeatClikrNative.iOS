//
//  SequencerGridView.swift
//  beatclikr
//
//  Created by Ben Funk on 6/11/26.
//

import SwiftUI

struct SequencerGridView: View {
    @ObservedObject var viewModel: SequencerViewModel

    private let cellWidth: CGFloat = 40

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                measureNumbersHeader
                ForEach(viewModel.selectedInstruments.sorted { $0.rawValue < $1.rawValue }, id: \.self) { instrument in
                    InstrumentTrackView(
                        instrument: instrument,
                        pattern: viewModel.pattern,
                        configuration: viewModel.configuration,
                        currentStep: viewModel.currentStep,
                        onToggle: { step in viewModel.toggleCell(instrument: instrument, step: step) },
                    )
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }

    private var measureNumbersHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 100, height: 20)
            ForEach(0 ..< viewModel.configuration.measuresCount, id: \.self) { measure in
                Text("\(measure + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: cellWidth * CGFloat(stepsPerMeasure), height: 20, alignment: .leading)
                    .padding(.leading, 4)
            }
        }
    }

    private var stepsPerMeasure: Int {
        viewModel.configuration.beatsPerMeasure * viewModel.configuration.subdivisionsPerBeat
    }
}
