//
//  InstantMetronomeView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftUI
import Awesome

struct InstantMetronomeView: View {
    @State var isBeat: Bool = false
    @State var showAlert: Bool
    @State var isPlaying: Bool
    
    @State var beatsPerMinute: Double
    @State var selectedGroove: Groove
    @State var beat: FileConstants
    @State var rhythm: FileConstants
    
    let metronome = MetronomeService.instance
    let defaults = UserDefaultsService.instance
    
    init () {
        _beatsPerMinute = State(initialValue: defaults.getInstantBpm())
        _showAlert = State(initialValue: false)
        _selectedGroove = State(initialValue: defaults.getInstantGroove())
        _isPlaying = State(initialValue: false)
        _beat = State(initialValue: defaults.getInstantBeat())
        _rhythm = State(initialValue: defaults.getInstantRhythm())
    }
    
    var body: some View {
        VStack() {
            MetronomePlayerView()
            Text("Tempo (BPM): \(FormatterHelper.formatDouble(beatsPerMinute))")
            Slider(value: $beatsPerMinute, in: 60...180, step: 1) {
                Text("Tempo")
            } minimumValueLabel: {
                Text("60")
            } maximumValueLabel: {
                Text("180")
            }
            .onChange(of: beatsPerMinute) { saveInstantBpm() }
            Grid(alignment: .trailing) {
                GridRow {
                    Text("Subdivisions")
                    Picker("Select Groove", selection: $selectedGroove) {
                        ForEach(Groove.allCases) {
                            option in
                            Text(String(describing: option))
                        }
                    }
                    .onChange(of: selectedGroove) { saveInstantGroove() }
                    .pickerStyle(.segmented)
                }
                GridRow {
                    Text("Beat")
                    Menu(content: {
                        Picker("Beat", selection: $beat) {
                            ForEach(InstrumentLists.beat) {
                                option in
                                Text(String(describing: option))
                            }
                        }
                        .onChange(of: beat) { saveInstantBeat() }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }, label: {
                        RectangleText("\(beat.description)", backgroundColor: .clear, foregroundColor: .blue)
                    })
                }
                GridRow {
                    Text("Rhythm")
                    Menu(content: {
                        Picker("Rhythm", selection: $rhythm) {
                            ForEach(InstrumentLists.rhythm) {
                                option in
                                Text(String(describing: option))
                            }
                        }
                        .onChange(of: rhythm) { saveInstantRhythm() }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }, label: {
                        RectangleText("\(rhythm.description)", backgroundColor: .clear, foregroundColor: .blue)
                    })
                    
                }
            }
            Button(action: {
                isPlaying = !isPlaying
                isPlaying ? play() : pause()
            }, label: {
                RectangleText(isPlaying ? "Pause" : "Play")
            })
            Spacer()
        }
        .onDisappear(perform: pause)
        .padding(.horizontal, 12)
    }
    
    private func play() {
        isPlaying = true
        let song = Song(title: "Instant", artist: "You!", beatsPerMinute: beatsPerMinute, beatsPerMeasure: 4, groove: selectedGroove)
        metronome.setup(beatName: beat.rawValue, rhythmName: rhythm.rawValue, song: song)
        metronome.start()
    }
    
    private func pause() {
        isPlaying = false
        metronome.stop()
    }
    
    private func saveInstantBpm() {
        defaults.setInstantBpm(val: beatsPerMinute)
        resetMetronome()
    }
    
    private func saveInstantGroove() {
        defaults.setInstantGroove(val: selectedGroove)
        resetMetronome()
    }
    
    private func saveInstantBeat() {
        defaults.setInstantBeat(val: beat)
        resetMetronome()
    }
    
    private func saveInstantRhythm() {
        defaults.setInstantRhythm(val: rhythm)
        resetMetronome()
    }
    
    private func resetMetronome() {
        if isPlaying {
            pause()
            play()
        }
    }
}

#Preview {
    InstantMetronomeView()
}
