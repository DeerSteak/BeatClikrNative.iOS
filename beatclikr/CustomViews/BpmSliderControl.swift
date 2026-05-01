//
//  BpmSliderControl.swift
//  beatclikr
//
//  Created by Ben Funk on 4/25/26.
//

import SwiftUI

struct BpmSliderControl: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = MetronomeConstants.minBPM...MetronomeConstants.maxBPM

    var body: some View {
        HStack(spacing: 8) {
            Button {
                value = max(range.lowerBound, value - 1)
            } label: {
                Image(systemName: "minus")
                    .font(.title3.bold())
                    .frame(width: 40, height: 40)
                    .foregroundColor(value == range.lowerBound ? .gray : .appPrimary)
            }
            .buttonStyle(.bordered)
            .clipShape(Circle())
            .accessibilityLabel("Decrease BPM")

            Slider(value: $value, in: range, step: 1)
                .tint(Color.appPrimary)

            Button {
                value = min(range.upperBound, value + 1)
            } label: {
                Image(systemName: "plus")
                    .font(.title3.bold())
                    .frame(width: 40, height: 40)
                    .foregroundColor(value == range.upperBound ? .gray : .appPrimary)
            }
            .buttonStyle(.bordered)
            .clipShape(Circle())
            .accessibilityLabel("Increase BPM")
        }
    }
}
