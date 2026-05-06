//
//  InstantMetronomeView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftData
import SwiftUI

struct InstantMetronomeView: View {
    @State var showAlert: Bool
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var model: MetronomePlaybackViewModel
    @EnvironmentObject var practiceHistory: PracticeHistoryViewModel

    init() {
        _showAlert = State(initialValue: false)
    }

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

                // Beat & Rhythm card
                CardContainer {
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
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onDisappear(perform: model.stop)
        .onAppear(perform: model.onAppear)
    }

    private func togglePlayPause() {
        if model.isPlaying {
            model.stop()
        } else {
            model.start()
            practiceHistory.recordSongPlayed(song: Song.instantSong, context: modelContext)
        }
    }
}

#Preview {
    let previewContainer = PreviewContainer([Song.self])
    return InstantMetronomeView()
        .modelContainer(previewContainer.container)
        .environmentObject(MetronomePlaybackViewModel())
}
