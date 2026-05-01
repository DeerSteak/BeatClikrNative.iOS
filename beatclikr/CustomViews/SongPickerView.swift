//
//  SongPickerView.swift
//  beatclikr
//

import SwiftUI
import SwiftData

struct SongPickerView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var model: PlaylistDetailViewModel
    @Query(sort: [SortDescriptor(\Song.title), SortDescriptor(\Song.artist)]) private var allSongs: [Song]
    let playlist: Playlist
    
    var body: some View {
        NavigationStack {
            List(allSongs) { song in
                Button {
                    model.addSongToPlaylist(song, playlist: playlist, context: modelContext)
                    dismiss()
                } label: {
                    SongListItemView(song: song)
                }
                .buttonStyle(.plain)
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
