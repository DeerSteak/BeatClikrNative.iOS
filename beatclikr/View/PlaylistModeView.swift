//
//  PlaylistModeView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/7/23.
//

import SwiftUI
import SwiftData

struct PlaylistModeView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var model: SongLibraryViewModel
    
    @Query(sort: \PlaylistEntry.sequence) private var entries: [PlaylistEntry]
    @Query(sort: [SortDescriptor(\Song.title), SortDescriptor(\Song.artist)]) private var allSongs: [Song]
    
    @State private var showingSongPicker = false
    
    private let backupService = iCloudBackupService.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                if !entries.isEmpty {
                    MetronomePlayerView()
                }
                List {
                    ForEach(entries) { entry in
                        if let song = entry.song {
                            NavigationLink {
                                SongDetailsView(song: song)
                            } label: {
                                SongListItemView(song: song)
                            }
                        }
                    }
                    .onDelete(perform: deleteEntries)
                    .onMove(perform: sortEntries)
                }
                .overlay {
                    if entries.isEmpty {
                        VStack {
                            Text("Press the + button to add a song")
                                .padding(.top, 40)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Playlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSongPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onChange(of: entries.count) { _, _ in
                Task {
                    try? await backupService.backupPlaylistEntries(entries)
                }
            }
            .sheet(isPresented: $showingSongPicker) {
                NavigationStack {
                    List(allSongs) { song in
                        Button {
                            addSongToPlaylist(song)
                            showingSongPicker = false
                        } label: {
                            SongListItemView(song: song)
                        }
                    }
                    .navigationTitle("Add Song")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingSongPicker = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func addSongToPlaylist(_ song: Song) {
        withAnimation {
            let entry = PlaylistEntry(song: song, sequence: entries.count)
            modelContext.insert(entry)
            try! modelContext.save()
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
            // Re-sequence remaining entries
            let remaining = entries.enumerated().filter { !offsets.contains($0.offset) }
            for (newIndex, element) in remaining.enumerated() {
                element.element.sequence = newIndex
            }
            try! modelContext.save()
        }
    }
    
    private func sortEntries(fromOffsets: IndexSet, toOffset: Int) {
        var revisedEntries = entries.map { $0 }
        revisedEntries.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (index, entry) in revisedEntries.enumerated() {
            entry.sequence = index
        }
    }
}

#Preview {
    PlaylistModeView()
        .modelContainer(for: [Song.self, PlaylistEntry.self], inMemory: true)
        .environmentObject(SongLibraryViewModel())
}
