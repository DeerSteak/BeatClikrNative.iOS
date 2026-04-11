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
                        }) {
                            Image(systemName: "minus")
                                .font(.title2.bold())
                                .frame(width: 44, height: 44)
                                .background(Color.appPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Decrease BPM")
                        Slider(value: $model.beatsPerMinute, in: MetronomeConstants.defaultMinSliderBPM...MetronomeConstants.defaultMaxSliderBPM, step: 1)
                        Button(action: {
                            model.beatsPerMinute = min(MetronomeConstants.defaultMaxSliderBPM, model.beatsPerMinute + 1)
                        }) {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .frame(width: 44, height: 44)
                                .background(Color.appPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Increase BPM")
                    }

                }
                Grid(alignment: .trailing, verticalSpacing: 16) {
                    GridRow {
                        Text("Groove")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(Groove.allCases) { option in
                                Button(action: {
                                    model.selectedGroove = option
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
                                .accessibilityAddTraits(model.selectedGroove == option ? .isSelected : [])
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
            .onAppear {
                model.clickerType = .instant
                UIApplication.shared.isIdleTimerDisabled = UserDefaultsService.instance.keepAwake
            }
            .padding(.all, 12)
            .background(Color(UIColor.systemGroupedBackground))
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
    

}

#Preview {
    let previewContainer = PreviewContainer([Song.self])
    return InstantMetronomeView()
        .modelContainer(previewContainer.container)
        .environmentObject(MetronomePlaybackViewModel())
    
}
