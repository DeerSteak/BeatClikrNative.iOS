//
//  SongPickerView.swift
//  beatclikr
//

import SwiftUI
import SwiftData

struct SongPickerView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var model: PlaylistModeViewModel
    @Query(sort: [SortDescriptor(\Song.title), SortDescriptor(\Song.artist)]) private var allSongs: [Song]
    let entries: [PlaylistEntry]

    var body: some View {
        NavigationStack {
            List(allSongs) { song in
                Button {
                    model.addSongToPlaylist(song, entries: entries, context: modelContext)
                    dismiss()
                } label: {
                    SongListItemView(song: song)
                }
            }
            .navigationTitle("Add Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
