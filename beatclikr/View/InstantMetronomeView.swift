//
//  InstantMetronomeView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftUI
import SwiftData

struct InstantMetronomeView: View {
    
    @State var showAlert: Bool
    @EnvironmentObject var model: MetronomePlaybackViewModel
    
    init () {
        _showAlert = State(initialValue: false)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    
                    // BPM card
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
                        }
                        HStack(spacing: 8) {
                            Button {
                                withAnimation {
                                    model.beatsPerMinute = max(MetronomeConstants.minBPM, model.beatsPerMinute - 1)
                                }
                            } label: {
                                Image(systemName: ImageConstants.subtract)
                                    .font(.title3.bold())
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(.bordered)
                            .clipShape(Circle())
                            .accessibilityLabel("Decrease BPM")
                            
                            Slider(value: Binding(
                                get: { model.beatsPerMinute },
                                set: { newValue in withAnimation { model.beatsPerMinute = newValue } }
                            ), in: MetronomeConstants.minBPM...MetronomeConstants.maxBPM, step: 1)
                            
                            Button {
                                withAnimation {
                                    model.beatsPerMinute = min(MetronomeConstants.maxBPM, model.beatsPerMinute + 1)
                                }
                            } label: {
                                Image(systemName: ImageConstants.add)
                                    .font(.title3.bold())
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(.bordered)
                            .clipShape(Circle())
                            .accessibilityLabel("Increase BPM")
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    // Groove card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Groove")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .textCase(.uppercase)
                            .padding(.horizontal, 4)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(Groove.allCases) { option in
                                Button {
                                    model.selectedGroove = option
                                } label: {
                                    Text(String(describing: option))
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(model.selectedGroove == option ? Color.accentColor : Color(UIColor.tertiarySystemFill))
                                        .foregroundStyle(model.selectedGroove == option ? Color.white : Color.primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(model.selectedGroove == option ? .isSelected : [])
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    // Beat & Rhythm card
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
                                    Image(systemName: ImageConstants.picker)
                                        .font(.caption2)
                                }
                                .foregroundStyle(Color.accentColor)
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
                                    Image(systemName: ImageConstants.picker)
                                        .font(.caption2)
                                }
                                .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    // Play / Pause
                    Button(action: togglePlayPause) {
                        Label(
                            model.isPlaying ? String(localized: "Pause") : String(localized: "Play"),
                            systemImage: model.isPlaying ? ImageConstants.pauseFill : ImageConstants.play
                        )
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onDisappear(perform: model.stop)
            .onAppear {
                model.clickerType = .instant
                UIApplication.shared.isIdleTimerDisabled = UserDefaultsService.instance.keepAwake
            }
            .navigationTitle("Instant Metronome")
            .navigationBarTitleDisplayMode(.automatic)
        }
    }
    
    private func togglePlayPause() {
        if model.isPlaying {
            model.stop()
        } else {
            model.start()
        }
    }
    

}

#Preview {
    let previewContainer = PreviewContainer([Song.self])
    return InstantMetronomeView()
        .modelContainer(previewContainer.container)
        .environmentObject(MetronomePlaybackViewModel())
    
}
