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
    @State var bpmText: String
    @State var beatsText: String
    @State var selectedGroove: Groove
    
    @State var showAlert: Bool
    
    var song: Song
    
    init () {
        self.song = Song(title: "", artist: "", beatsPerMinute: 60, beatsPerMeasure: 4, groove: .eighth)
        _title = State(initialValue: self.song.title!)
        _artist = State(initialValue: self.song.artist!)
        _bpmText = State(initialValue: FormatterHelper.formatDouble(self.song.beatsPerMinute!))
        _beatsText = State(initialValue: "\(self.song.beatsPerMeasure!)")
        _showAlert = State(initialValue: false)
        _selectedGroove = State(initialValue: .eighth)
    }
    
    init (song: Song) {
        self.song = song
        _title = State(initialValue: song.title!)
        _artist = State(initialValue: song.artist!)
        _bpmText = State(initialValue: FormatterHelper.formatDouble(song.beatsPerMinute!))
        _beatsText = State(initialValue: "\(song.beatsPerMeasure!)")
        _showAlert = State(initialValue: false)
        _selectedGroove = State(initialValue: song.groove!)
    }
    
    private var parsedBPM: Double? { Double(bpmText) }
    private var parsedBeats: Int? { Int(beatsText) }
    
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
                    TextField("Beats per Minute", text: $bpmText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
                GridRow {
                    Text("Beats / Bar")
                    TextField("Beats per Measure", text: $beatsText)
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
                RectangleText(String(localized: "Save"), backgroundColor: .clear, foregroundColor: songIsValid() ? .blue : .gray)
            })
            .alert(isPresented: $showAlert, content: {
                Alert(title: Text("Error saving"))
            })
            .disabled(!songIsValid())
            Button(action: {
                dismiss()
            }, label: {
                RectangleText(String(localized: "Cancel"), backgroundColor: .red, foregroundColor: .white)
            })
            Spacer()
                .navigationBarTitleDisplayMode(.automatic)
                .navigationTitle(navTitle())
        }
        .padding()
    }
    
    public func saveSong() -> Bool {
        guard let bpm = parsedBPM, let beats = parsedBeats else { return false }
        song.title = title
        song.artist = artist
        song.beatsPerMinute = bpm
        song.beatsPerMeasure = beats
        song.groove = selectedGroove
        
        if (song.title?.isEmpty ?? true || song.artist?.isEmpty ?? true || bpm < 30 || beats < 1) {
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
        guard let bpm = parsedBPM, let beats = parsedBeats else { return false }
        return title != "" && artist != "" && bpm >= 30 && beats > 0
    }
    
    public func navTitle() -> String {
        return (song.title ?? "").isEmpty ? String(localized: "Add Song") : String(localized: "Song Details")
    }
}

#Preview {
    SongDetailsView()
        .environmentObject(SongLibraryViewModel())
}
