//
//  PolyrhythmView.swift
//  beatclikr
//

import SwiftUI

struct PolyrhythmView: View {
    @EnvironmentObject var model: PolyrhythmViewModel

    var body: some View {
        ScrollView {
                VStack(spacing: 8) {

                    // Ratio selector card
                    VStack(spacing: 16) {
                        HStack(alignment: .center, spacing: 0) {
                            PolyrhythmCountSelector(label: "Rhythm", value: $model.beats, range: 1...9)
                            Text(":")
                                .font(.system(size: 48, weight: .thin))
                                .foregroundStyle(.secondary)
                                .frame(width: 32)
                            PolyrhythmCountSelector(label: "Beat", value: $model.against, range: 1...9)
                        }

                        // Visual dot indicators
                        VStack(spacing: 12) {
                            PolyrhythmDotRow(
                                label: "Beat",
                                count: model.against,
                                activeIndex: model.activeBeatIndex,
                                pulse: model.beatPulse,
                                color: Color.appPrimary
                            )
                            PolyrhythmDotRow(
                                label: "Rhythm",
                                count: model.beats,
                                activeIndex: model.activeRhythmIndex,
                                pulse: model.rhythmPulse,
                                color: Color.secondary
                            )
                            PolyrhythmPlayheadRow(
                                progress: model.cycleProgress,
                                isPlaying: model.isPlaying
                            )
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)

                    // BPM card
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            VStack(spacing: 8) {
                                Text(FormatterHelper.formatDouble(model.bpm))
                                    .font(.system(size: 60, weight: .thin, design: .rounded))
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                Text("BPM")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .tracking(2)
                                    .textCase(.uppercase)
                            }
                            TapTempoButton(bpm: $model.bpm)
                        }
                        BpmSliderControl(value: Binding(
                            get: { model.bpm },
                            set: { newValue in withAnimation { model.bpm = newValue } }
                        ))
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)

                    // Sound pickers card
                    VStack(spacing: 0) {
                        HStack {
                            Text("Beat")
                                .foregroundStyle(.primary)
                            Spacer()
                            Menu {
                                Picker("Beat", selection: $model.beat) {
                                    ForEach(InstrumentLists.beat) { option in
                                        Text(String(describing: option))
                                    }
                                }
                                .pickerStyle(.inline)
                                .labelsHidden()
                            } label: {
                                HStack(spacing: 4) {
                                    Text(model.beat.description)
                                    Image(systemName: ImageConstants.chevronUpDown)
                                        .font(.caption2)
                                }
                                .foregroundStyle(Color.accent)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)

                        Divider()
                            .padding(.leading, 12)

                        HStack {
                            Text("Rhythm")
                                .foregroundStyle(.primary)
                            Spacer()
                            Menu {
                                Picker("Rhythm", selection: $model.rhythm) {
                                    ForEach(InstrumentLists.rhythm) { option in
                                        Text(String(describing: option))
                                    }
                                }
                                .pickerStyle(.inline)
                                .labelsHidden()
                            } label: {
                                HStack(spacing: 4) {
                                    Text(model.rhythm.description)
                                    Image(systemName: ImageConstants.chevronUpDown)
                                        .font(.caption2)
                                }
                                .foregroundStyle(Color.accent)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)

                    // Play / Pause
                    Button(action: model.togglePlayPause) {
                        Label(
                            model.isPlaying ? String(localized: "Pause") : String(localized: "Play"),
                            systemImage: model.isPlaying ? ImageConstants.pause : ImageConstants.play
                        )
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Color.appPrimary)
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onDisappear(perform: model.stop)
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = UserDefaultsService.instance.keepAwake
            }
    }
}

// MARK: - Subviews

private struct PolyrhythmCountSelector: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .tracking(1)
                .textCase(.uppercase)
                .lineLimit(1)
            HStack(spacing: 8) {
                Button {
                    if value > range.lowerBound { value -= 1 }
                } label: {
                    Image(systemName: ImageConstants.subtract)
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .frame(minWidth: 44)

                Button {
                    if value < range.upperBound { value += 1 }
                } label: {
                    Image(systemName: ImageConstants.add)
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(value >= range.upperBound)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PolyrhythmDotRow: View {
    let label: String
    let count: Int
    let activeIndex: Int
    let pulse: Double
    let color: Color

    @ScaledMetric private var labelWidth: CGFloat = 68

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .tracking(1)
                .textCase(.uppercase)
                .lineLimit(1)
                .frame(width: labelWidth, alignment: .leading)

            VStack(spacing: 4) {
                HStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { i in
                        Circle()
                            .fill(color)
                            .frame(width: 18, height: 18)
                            .opacity(i == activeIndex ? (0.25 + 0.75 * pulse) : 0.25)
                            .scaleEffect(i == activeIndex ? (0.85 + 0.15 * pulse) : 0.85)
                        Spacer(minLength: 0)
                    }
                }
                Capsule()
                    .fill(color.opacity(0.2))
                    .frame(height: 2)
            }
        }
    }
}

private struct PolyrhythmPlayheadRow: View {
    let progress: Double
    let isPlaying: Bool

    @ScaledMetric private var labelWidth: CGFloat = 68

    var body: some View {
        HStack(spacing: 8) {
            Color.clear
                .frame(width: labelWidth, height: 14)

            GeometryReader { geo in
                let dotSize: CGFloat = 14
                let midY = geo.size.height / 2
                let dotX = dotSize / 2 + (geo.size.width - dotSize) * CGFloat(progress)

                Capsule()
                    .fill(Color.orange.opacity(0.25))
                    .frame(width: geo.size.width, height: 2)
                    .position(x: geo.size.width / 2, y: midY)

                Circle()
                    .fill(Color.orange)
                    .frame(width: dotSize, height: dotSize)
                    .position(x: dotX, y: midY)
                    .opacity(isPlaying ? 1.0 : 0.3)
            }
            .frame(height: 14)
        }
    }
}

#Preview {
    PolyrhythmView()
        .environmentObject(PolyrhythmViewModel())
}
