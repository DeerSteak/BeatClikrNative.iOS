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
    @State var beatsPerMinute: Double
    @State var selectedGroove: Groove
    @State var showAlert: Bool
    @State var isPlaying: Bool
    
    let metronome = MetronomeService.instance
    
    init () {
        _beatsPerMinute = State(initialValue: 60)
        _showAlert = State(initialValue: false)
        _selectedGroove = State(initialValue: .eighth)
        _isPlaying = State(initialValue: false)
    }
    
    var body: some View {
        VStack {
            MetronomePlayerView()
            Grid {
                GridRow {
                    Text("Tempo (BPM)")
                    TextField("Beats per Minute", value: $beatsPerMinute, formatter: FormatterHelper.numberFormatter)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
                GridRow {
                    Text("Groove")
                    Picker("Select Groove", selection: $selectedGroove) {
                        ForEach(Groove.allCases) {
                            option in
                            Text(String(describing: option))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            Button(action: {
                isPlaying = !isPlaying
                isPlaying ? play() : pause()
            }, label: {
                Text(isPlaying ? "Pause" : "Play")
            })
        }
        .onDisappear(perform: pause)
    }
    
    private func play() {
        print("Starting")
        let song = Song(title: "Instant", artist: "You!", beatsPerMinute: beatsPerMinute, beatsPerMeasure: 4, groove: selectedGroove)
        metronome.setup(beatName: FileConstants.ClickHi, rhythmName: FileConstants.ClickLo, song: song)
        metronome.start()
    }
    
    private func pause() {
        metronome.stop()
    }
}

#Preview {
    InstantMetronomeView()
}
