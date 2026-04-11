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
    @EnvironmentObject var model: PlaylistModeViewModel
    @Query(sort: \PlaylistEntry.sequence) private var entries: [PlaylistEntry]
    @Query(sort: [SortDescriptor(\Song.title), SortDescriptor(\Song.artist)]) private var allSongs: [Song]
    
    @State private var editMode: EditMode = .inactive
    @State private var showingSongPicker = false
    @State private var tappedId: String?
    @State private var editingSong: Song?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    if let song = entry.song {
                        HStack {
                            SongListItemView(song: song)
                            Spacer()
                            if editMode.isEditing {
                                Button {
                                    editingSong = song
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 8)
                            }
                        }
                        .contentShape(Rectangle())
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(tappedId == entry.id ? Color.accentColor.opacity(0.25) : Color.clear)
                                .animation(.easeOut(duration: 0.5), value: tappedId)
                        )
                        .onTapGesture {
                            guard !editMode.isEditing else { return }
                            tappedId = entry.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                tappedId = nil
                            }
                            model.playSong(song)
                        }
                    }
                }
                .onDelete(perform: editMode.isEditing ? { offsets in model.deleteEntries(offsets: offsets, entries: entries, context: modelContext) } : nil)
                .onMove { fromOffsets, toOffset in model.sortEntries(fromOffsets: fromOffsets, toOffset: toOffset, entries: entries) }
            }
            .environment(\.editMode, $editMode)
            .overlay {
                if entries.isEmpty {
                    VStack {
                        Text("Press the + button to add a song")
                            .padding(.top, 40)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Playlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if (entries.count > 0) {
                        MetronomePlayerView(size: MetronomeConstants.playerViewToolbarSize)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editMode.isEditing ? "Done" : "Edit") {
                        editMode = editMode.isEditing ? .inactive : .active
                    }
                }
                ToolbarItem {
                    Button {
                        showingSongPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                if model.isPlaying {
                    ToolbarItem {
                        Button(action: model.stop) {
                            Image(systemName: "pause")
                        }
                    }
                }
            }
            .toolbarTitleDisplayMode(.automatic)
            .sheet(item: $editingSong) { song in
                SongDetailsView(song: song)
            }
            .sheet(isPresented: $showingSongPicker) {
                NavigationStack {
                    List(allSongs) { song in
                        Button {
                            model.addSongToPlaylist(song, entries: entries, context: modelContext)
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
        .onDisappear(perform: model.stop)
    }
}

#Preview {
    PlaylistModeView()
        .modelContainer(for: [Song.self, PlaylistEntry.self], inMemory: true)
        .environmentObject(PlaylistModeViewModel())
        .environmentObject(MetronomePlaybackViewModel())
}
