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
    var song: Song
    @State var navBarTitle: String
    @State var showAlert: Bool
    
    init () {
        self.song = Song()
        _title = State(initialValue: self.song.title)
        _artist = State(initialValue: self.song.artist)
        _beatsPerMinute = State(initialValue: self.song.beatsPerMinute)
        _beatsPerMeasure = State(initialValue: self.song.beatsPerMeasure)
        _navBarTitle = State(initialValue: "Add Song")
        _showAlert = State(initialValue: false)
        
    }
    
    init (song: Song) {
        self.song = song
        _navBarTitle = State(initialValue: "Song Details")
        _title = State(initialValue: song.title)
        _artist = State(initialValue: song.artist)
        _beatsPerMinute = State(initialValue: song.beatsPerMinute)
        _beatsPerMeasure = State(initialValue: song.beatsPerMeasure)
        _showAlert = State(initialValue: false)
    }
    
    var body: some View {
        VStack {
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
            }
            .contentMargins(10)
            .padding()
            Button("Save") {
                if (saveSong()) {
                    dismiss()
                }
            }
            .alert(isPresented: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Is Presented@*/.constant(false)/*@END_MENU_TOKEN@*/, content: {
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Content@*/Alert(title: Text("Alert"))/*@END_MENU_TOKEN@*/
            })
            .disabled(title == "" || artist == "" || beatsPerMinute < 30 || beatsPerMeasure <= 0)
        }
        .navigationTitle(navBarTitle)
        .navigationBarBackButtonHidden(true)
    }
    
    public func saveSong() -> Bool {
        song.title = title
        song.artist = artist
        song.beatsPerMinute = beatsPerMinute
        song.beatsPerMeasure = beatsPerMeasure
        
        //validate
        if (song.title.isEmpty || song.artist.isEmpty || song.beatsPerMinute < 30 || song.beatsPerMeasure < 1) {
            return false
        }
        modelContext.insert(song)
        do {
            try modelContext.save()
            return true
        } catch {
            print(error)
            return false
        }
    }
}

#Preview {
    SongDetailsView()
        .environmentObject(SongLibraryViewModel())
}
