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
            VStack(spacing: 20) {
                HStack{
                    Spacer()
                    ZStack {
                        // Invisible spacer to maintain fixed height at 100% scale
                        Color.clear
                            .frame(width: MetronomeConstants.playerViewDefaultSize, height: MetronomeConstants.playerViewDefaultSize)
                        
                        MetronomePlayerView()
                    }
                    .padding(.all, 12)
                    Spacer()
                }
                VStack {
                    Text("Tempo (BPM): \(FormatterHelper.formatDouble(model.beatsPerMinute))")
                    HStack {
                        Button(action: {
                            model.beatsPerMinute = max(MetronomeConstants.defaultMinSliderBPM, model.beatsPerMinute - 1)
                            resetMetronome()
                        }) {
                            Image(systemName: "minus")
                                .font(.title2.bold())
                                .frame(width: 44, height: 44)
                                .background(Color.appPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        Slider(value: $model.beatsPerMinute, in: MetronomeConstants.defaultMinSliderBPM...MetronomeConstants.defaultMaxSliderBPM, step: 1)
                        Button(action: {
                            model.beatsPerMinute = min(MetronomeConstants.defaultMaxSliderBPM, model.beatsPerMinute + 1)
                            resetMetronome()
                        }) {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .frame(width: 44, height: 44)
                                .background(Color.appPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .onChange(of: model.beatsPerMinute) {
                        resetMetronome()
                    }
                }
                Grid(alignment: .trailing, verticalSpacing: 16) {
                    GridRow {
                        Text("Groove")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(Groove.allCases) { option in
                                Button(action: {
                                    model.selectedGroove = option
                                    resetMetronome()
                                }) {
                                    Text(String(describing: option))
                                        .font(.caption)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(model.selectedGroove == option ? Color.accentColor : Color(UIColor.systemGray5))
                                        .foregroundColor(model.selectedGroove == option ? .white : .primary)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    GridRow {
                        Text("Beat")
                        Menu(content: {
                            Picker("Beat", selection: $model.beat) {
                                ForEach(InstrumentLists.beat) {
                                    option in
                                    Text(String(describing: option))
                                }
                            }
                            .onChange(of: model.beat) { resetMetronome() }
                            .pickerStyle(.inline)
                            .labelsHidden()
                        }, label: {
                            RectangleText("\(model.beat.description)", backgroundColor: Color(UIColor.systemBackground), foregroundColor: .appPrimary)
                        })
                    }
                    GridRow {
                        Text("Rhythm")
                        Menu(content: {
                            Picker("Rhythm", selection: $model.rhythm) {
                                ForEach(InstrumentLists.rhythm) {
                                    option in
                                    Text(String(describing: option))
                                }
                            }
                            .onChange(of: model.rhythm) { resetMetronome() }
                            .pickerStyle(.inline)
                            .labelsHidden()
                        }, label: {
                            RectangleText("\(model.rhythm.description)", backgroundColor: Color(UIColor.systemBackground), foregroundColor: .appPrimary)
                        })
                        
                    }
                }
                Button(action: togglePlayPause, label: {
                    RectangleText(model.isPlaying ? String(localized: "Pause") : String(localized: "Play"))
                })
                
                Spacer()
                
            }
            .onDisappear(perform: model.stop)
            .onAppear(perform: { model.clickerType = .instant })
            .padding(.all, 12)
            .navigationTitle("Instant Metronome")
        }
    }
    
    private func togglePlayPause() {
        if model.isPlaying {
            model.stop()
        } else {
            model.start()
        }
    }
    
    private func resetMetronome() {
        let wasPlaying = model.isPlaying
        model.resetMetronome()
        if wasPlaying {
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
