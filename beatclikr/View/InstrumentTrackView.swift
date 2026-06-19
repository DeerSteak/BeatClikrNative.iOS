//
//  InstrumentTrackView.swift
//  beatclikr
//
//  Created by Ben Funk on 6/14/26.
//

import SwiftUI

struct InstrumentTrackView: View {
    let instrument: FileConstants
    let pattern: SequencePattern
    let configuration: SequencerConfiguration
    let currentStep: Int
    let onToggle: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text(instrument.description)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 100, height: 40, alignment: .leading)
                .padding(.leading, 8)
                .background(Color(UIColor.secondarySystemBackground))

            ForEach(0 ..< configuration.totalSteps, id: \.self) { step in
                BeatCellView(
                    velocity: pattern.velocity(instrument: instrument, at: step),
                    isCurrentStep: step == currentStep,
                    isMeasureBoundary: isMeasureBoundary(step),
                    isBeatBoundary: isBeatBoundary(step),
                    onTap: { onToggle(step) },
                )
            }
        }
    }

    private func isMeasureBoundary(_ step: Int) -> Bool {
        let stepsPerMeasure = configuration.beatsPerMeasure * configuration.subdivisionsPerBeat
        return step % stepsPerMeasure == 0
    }

    private func isBeatBoundary(_ step: Int) -> Bool {
        configuration.subdivisionsPerBeat > 1 && step % configuration.subdivisionsPerBeat == 0
    }
}
