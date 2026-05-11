//
//  MetronomeView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftData
import SwiftUI

struct MetronomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var model: MetronomePlaybackViewModel
    @EnvironmentObject var practiceHistory: PracticeHistoryViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // BPM card
                CardContainer {
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            ZStack {
                                Color.clear.frame(width: MetronomeConstants.playerViewDefaultSize, height: MetronomeConstants.playerViewDefaultSize)
                                MetronomePlayerView(size: MetronomeConstants.playerViewDefaultSize)
                            }
                            VStack(spacing: 8) {
                                Text(FormatterHelper.formatDouble(model.beatsPerMinute))
                                    .font(.system(size: 60, weight: .thin, design: .rounded))
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                Text("BPM")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .tracking(2)
                                    .textCase(.uppercase)
                            }
                            TapTempoButton(bpm: $model.beatsPerMinute)
                        }
                        BpmSliderControl(value: Binding(
                            get: { model.beatsPerMinute },
                            set: { newValue in withAnimation { model.beatsPerMinute = newValue } },
                        ))
                        .disabled(model.rampEnabled && model.isPlaying)
                    }
                    .padding(12)
                }

                // Groove card
                CardContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Groove")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .textCase(.uppercase)
                            .padding(.horizontal, 4)
                        GrooveSelectorView(selection: $model.selectedGroove, beatPattern: $model.selectedBeatPattern)
                    }
                    .padding(12)
                }

                // Tempo Ramp card
                CardContainer {
                    VStack(spacing: 0) {
                        Toggle(isOn: $model.rampEnabled) {
                            Text("Tempo Ramp")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        if model.rampEnabled {
                            VStack(spacing: 0) {
                                Divider()
                                    .padding(.leading, 12)
                                HStack {
                                    Text("Increase by")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Menu {
                                        Picker("Increase by", selection: $model.rampIncrement) {
                                            ForEach([1, 2, 5, 10], id: \.self) { value in
                                                Text("\(value) BPM").tag(value)
                                            }
                                        }
                                        .pickerStyle(.inline)
                                        .labelsHidden()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text("\(model.rampIncrement) BPM")
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
                                    Text("Every")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Menu {
                                        Picker("Every", selection: $model.rampInterval) {
                                            ForEach([4, 8, 16, 32, 48, 64], id: \.self) { value in
                                                Text("\(value) beats").tag(value)
                                            }
                                        }
                                        .pickerStyle(.inline)
                                        .labelsHidden()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text("\(model.rampInterval) beats")
                                            Image(systemName: ImageConstants.chevronUpDown)
                                                .font(.caption2)
                                        }
                                        .foregroundStyle(Color.accent)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }

                // Play / Pause
                Button(action: togglePlayPause) {
                    Label(
                        model.isPlaying ? String(localized: "Pause") : String(localized: "Play"),
                        systemImage: model.isPlaying ? ImageConstants.pause : ImageConstants.play,
                    )
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color.appPrimary)
            }
            .animation(.easeInOut(duration: 0.25), value: model.rampEnabled)
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onDisappear(perform: model.stop)
        .onAppear {
            model.clickerType = .metronome
        }
    }

    private func togglePlayPause() {
        if model.isPlaying {
            model.stop()
        } else {
            model.start()
            practiceHistory.recordMetronomePractice(context: modelContext)
        }
    }
}

#Preview {
    let previewContainer = PreviewContainer([Song.self, PracticeSession.self, PracticedSong.self])
    return MetronomeView()
        .modelContainer(previewContainer.container)
        .environmentObject(MetronomePlaybackViewModel())
        .environmentObject(PracticeHistoryViewModel())
}
