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
    @State var bpm: Double
    @State var beats: Int
    @State var selectedGroove: Groove
    @State var selectedBeatPattern: BeatPattern?

    @State var showAlert: Bool

    var song: Song

    init() {
        song = Song(title: "", artist: "", beatsPerMinute: 60, beatsPerMeasure: 4, groove: .eighth)
        _title = State(initialValue: "")
        _artist = State(initialValue: "")
        _bpm = State(initialValue: 60)
        _beats = State(initialValue: 4)
        _showAlert = State(initialValue: false)
        _selectedGroove = State(initialValue: .eighth)
        _selectedBeatPattern = State(initialValue: nil)
    }

    init(song: Song) {
        self.song = song
        _title = State(initialValue: song.title ?? "")
        _artist = State(initialValue: song.artist ?? "")
        _bpm = State(initialValue: song.beatsPerMinute ?? 60)
        _beats = State(initialValue: song.beatsPerMeasure ?? 4)
        _showAlert = State(initialValue: false)
        _selectedGroove = State(initialValue: song.groove ?? .eighth)
        _selectedBeatPattern = State(initialValue: BeatPattern(rawValue: song.beatPattern ?? ""))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Song Info") {
                    LabeledContent("Title") {
                        TextField("Required", text: $title)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.words)
                    }
                    LabeledContent("Artist") {
                        TextField("Required", text: $artist)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.words)
                    }
                }
                Section("Tempo") {
                    LabeledContent("BPM") {
                        Text(FormatterHelper.formatDouble(bpm))
                            .font(.system(size: 28, weight: .thin, design: .rounded))
                            .monospacedDigit()
                    }
                    HStack {
                        Spacer()
                        TapTempoButton(bpm: $bpm)
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    BpmSliderControl(value: $bpm)
                    Stepper("Beats per Bar: \(beats)", value: $beats, in: 1 ... 16, step: 1)
                }
                Section("Groove") {
                    GrooveSelectorView(selection: $selectedGroove, beatPattern: $selectedBeatPattern)
                        .padding(.vertical, 4)
                }
            }
            .navigationTitle(navTitle())
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if saveSong() { dismiss() }
                    }
                    .disabled(!songIsValid())
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error saving"))
            }
        }
    }

    func saveSong() -> Bool {
        song.title = title
        song.artist = artist
        song.beatsPerMinute = bpm
        song.beatsPerMeasure = beats
        song.groove = selectedGroove
        song.beatPattern = selectedGroove.isOddMeter ? selectedBeatPattern?.rawValue : nil

        if song.title?.isEmpty ?? true || song.artist?.isEmpty ?? true {
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

    func songIsValid() -> Bool {
        return title != "" && artist != "" && bpm >= MetronomeConstants.minBPM && bpm <= MetronomeConstants.maxBPM
    }

    func navTitle() -> String {
        return (song.title ?? "").isEmpty ? String(localized: "Add Song") : String(localized: "Song Details")
    }
}

#Preview {
    SongDetailsView()
        .environmentObject(SongLibraryViewModel())
}
