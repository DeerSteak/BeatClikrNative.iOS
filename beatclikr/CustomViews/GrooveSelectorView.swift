//
//  GrooveSelectorView.swift
//  beatclikr
//
//  Created by Ben Funk on 4/25/26.
//

import SwiftUI

struct GrooveSelectorView: View {
    @Binding var selection: Groove
    @Binding var beatPattern: BeatPattern?

    private let standardGrooves: [Groove] = [.quarter, .eighth, .triplet, .sixteenth]

    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(standardGrooves) { groove in
                    Button {
                        selection = groove
                    } label: {
                        Text(String(describing: groove))
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selection == groove ? Color.appPrimary : Color(.tertiarySystemFill))
                            .foregroundStyle(selection == groove ? Color.white : Color.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == groove ? .isSelected : [])
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                Button {
                    selection = .oddMeterQuarter
                    if beatPattern == nil { beatPattern = .sevenEightA }
                } label: {
                    Text(String(describing: Groove.oddMeterQuarter))
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == .oddMeterQuarter ? Color.appPrimary : Color(.tertiarySystemFill))
                        .foregroundStyle(selection == .oddMeterQuarter ? Color.white : Color.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == .oddMeterQuarter ? .isSelected : [])

                Button {
                    selection = .oddMeterEighth
                    if beatPattern == nil { beatPattern = .sevenEightA }
                } label: {
                    Text(String(describing: Groove.oddMeterEighth))
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == .oddMeterEighth ? Color.appPrimary : Color(.tertiarySystemFill))
                        .foregroundStyle(selection == .oddMeterEighth ? Color.white : Color.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == .oddMeterEighth ? .isSelected : [])
            }

            if selection.isOddMeter {
                Menu {
                    Picker("Pattern", selection: Binding(
                        get: { beatPattern ?? .sevenEightA },
                        set: { beatPattern = $0 }
                    )) {
                        ForEach(BeatPattern.allCases) { pattern in
                            Text(pattern.displayName).tag(pattern)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } label: {
                    HStack(spacing: 4) {
                        Text((beatPattern ?? .sevenEightA).displayName)
                        Image(systemName: ImageConstants.chevronUpDown)
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}
