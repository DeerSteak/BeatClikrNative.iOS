//
//  InstantMetronomeView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftUI

struct InstantMetronomeView: View {
    
    @State var showAlert: Bool
    @EnvironmentObject var model: MetronomePlaybackViewModel
    
    init () {
        _showAlert = State(initialValue: false)
    }
    
    var body: some View {
        Grid(alignment: .trailing, verticalSpacing: 16) {
            HStack{
                Spacer()
                MetronomePlayerView()
                    .padding(.all, 12)
                Spacer()
            }
            VStack {
                Text("Tempo (BPM): \(FormatterHelper.formatDouble(model.beatsPerMinute))")
                Slider(value: $model.beatsPerMinute, in: 60...180, step: 1) {
                    Text("Tempo")
                } minimumValueLabel: {
                    Text("60")
                } maximumValueLabel: {
                    Text("180")
                }
                .onChange(of: model.beatsPerMinute) {
                    resetMetronome()
                }
            }
            GridRow {
                Text("Subdivisions")
                Picker("Select Groove", selection: $model.selectedGroove) {
                    ForEach(Groove.allCases) {
                        option in
                        Text(String(describing: option))
                    }
                }
                .onChange(of: model.selectedGroove) { resetMetronome() }
                .pickerStyle(.segmented)
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
                    RectangleText("\(model.beat.description)", backgroundColor: .clear, foregroundColor: .appPrimary)
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
                    RectangleText("\(model.rhythm.description)", backgroundColor: .clear, foregroundColor: .appPrimary)
                })
                
            }
            Button(action: togglePlayPause, label: {
                RectangleText(model.isPlaying ? "Pause" : "Play")
            })
            
            Spacer()
            
        }
        .onDisappear(perform: model.stop)
        .onAppear(perform: { model.clickerType = .instant })
        .padding(.all, 12)
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
    InstantMetronomeView()
}
