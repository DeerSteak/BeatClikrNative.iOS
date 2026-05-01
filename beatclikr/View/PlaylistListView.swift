//
//  PlaylistListView.swift
//  beatclikr
//
//  created by Ben Funk on 4/30/26
//

import SwiftUI
import SwiftData

struct PlaylistListView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var model: PlaylistListViewModel
    @Query(sort: \Playlist.createdAt) private var playlists: [Playlist]
    
    @State private var path = NavigationPath()
    @State private var editMode: EditMode = .inactive
    @State private var showingNewPlaylistAlert = false
    @State private var newPlaylistName = ""
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(playlists) { playlist in
                    NavigationLink(value: playlist) {
                        Text(playlist.name ?? "Untitled")
                    }
                }
                .onDelete { offsets in
                    model.deletePlaylists(offsets: offsets, playlists: playlists, context: modelContext)
                }
            }
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
            .environment(\.editMode, $editMode)
            .overlay {
                if playlists.isEmpty {
                    VStack {
                        Text("Press the + button to create a playlist")
                            .padding(.top, 40)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Playlists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editMode.isEditing ? "Done" : "Edit") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
                    }
                    .disabled(playlists.isEmpty)
                }
                ToolbarItem {
                    Button {
                        newPlaylistName = ""
                        showingNewPlaylistAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Playlist")
                }
            }
            .alert("New Playlist", isPresented: $showingNewPlaylistAlert) {
                TextField("Name", text: $newPlaylistName)
                Button("Create") {
                    let name = newPlaylistName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    let playlist = model.createPlaylist(name: name, context: modelContext)
                    path.append(playlist)
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        .onDisappear { path = NavigationPath() }
    }
}

#Preview {
    let preview = PreviewContainer([Song.self, PlaylistEntry.self, Playlist.self])
    let songs = preview.addMockSongs()
    preview.addMockPlaylist(named: "Rock Classics", songs: songs)
    preview.addMockPlaylist(named: "Ballads", songs: Array(songs.prefix(2)))
    
    return PlaylistListView()
        .modelContainer(preview.container)
        .environmentObject(PlaylistListViewModel())
        .environmentObject(MetronomePlaybackViewModel())
}
