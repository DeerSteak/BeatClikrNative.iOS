//
//  SongDetailsView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import SwiftUI

struct SongDetailsView: View {
    @EnvironmentObject var model: SongLibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State var title: String
    @State var artist: String
    @State var beatsPerMinute: Double
    @State var beatsPerMeasure: Int
    @State var selectedGroove: Groove
    
    @State var showAlert: Bool
    
    var song: Song
    
    init () {
        self.song = Song()
        _title = State(initialValue: self.song.title)
        _artist = State(initialValue: self.song.artist)
        _beatsPerMinute = State(initialValue: self.song.beatsPerMinute)
        _beatsPerMeasure = State(initialValue: self.song.beatsPerMeasure)
        _showAlert = State(initialValue: false)
        _selectedGroove = State(initialValue: .eighth)
    }
    
    init (song: Song) {
        self.song = song
        _title = State(initialValue: song.title)
        _artist = State(initialValue: song.artist)
        _beatsPerMinute = State(initialValue: song.beatsPerMinute)
        _beatsPerMeasure = State(initialValue: song.beatsPerMeasure)
        _showAlert = State(initialValue: false)
        _selectedGroove = State(initialValue: song.groove )
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 10) {
            Grid {
                GridRow {
                    Text("Title")
                        .gridColumnAlignment(.trailing)
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                GridRow {
                    Text("Artist")
                    TextField("Artist", text: $artist)
                        .textFieldStyle(.roundedBorder)
                }
                GridRow {
                    Text("Tempo (BPM)")
                    TextField("Beats per Minute", value: $beatsPerMinute, formatter: FormatterHelper.numberFormatter)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
                GridRow {
                    Text("Beats / Bar")
                    TextField("Beats per Measure", value: $beatsPerMeasure, formatter: FormatterHelper.numberFormatter)
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
            .contentMargins(10)
            
            Button(action: {
                if (saveSong()) {
                    dismiss()
                }
            }, label: {
                RectangleText("Save", color: songIsValid() ? .blue : .gray)
            })
            .alert(isPresented: $showAlert, content: {
                Alert(title: Text("Error saving"))
            })
            .disabled(title == "" || artist == "" || beatsPerMinute < 30 || beatsPerMeasure <= 0)
            Button(action: {
                dismiss()
            }, label: {
                RectangleText("Cancel", color: .red)
            })
            Spacer()
                .navigationBarTitleDisplayMode(.automatic)
                .navigationTitle(navTitle())
        }
        .padding()
    }
    
    public func saveSong() -> Bool {
        song.title = title
        song.artist = artist
        song.beatsPerMinute = beatsPerMinute
        song.beatsPerMeasure = beatsPerMeasure
        
        if (song.title.isEmpty || song.artist.isEmpty || song.beatsPerMinute < 30 || song.beatsPerMeasure < 1) {
            return false
        }
        modelContext.insert(song)
        do {
            try modelContext.save()
            return true
        } catch {
            return false
        }
    }
    
    public func songIsValid() -> Bool {
        return title != "" && artist != "" && beatsPerMinute >= 30 && beatsPerMeasure > 0
    }
    
    public func navTitle() -> String {
        return song.title.isEmpty ? "Add Song" : "Song Details"
    }
}

#Preview {
    SongDetailsView()
        .environmentObject(SongLibraryViewModel())
        .modelContainer(for: Song.self, inMemory: true)
}
