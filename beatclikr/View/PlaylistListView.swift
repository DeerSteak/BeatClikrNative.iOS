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
    @Query(sort: \Playlist.name) private var playlists: [Playlist]

    @State private var path = NavigationPath()
    @State private var editMode: EditMode = .inactive
    @AppStorage(PreferenceKeys.playlistSortAscending) private var sortAscending = true
    @State private var showingNewPlaylistAlert = false
    @State private var newPlaylistName = ""
    @State private var showingRenameAlert = false
    @State private var renameText = ""
    @State private var playlistToRename: Playlist?

    private var sortedPlaylists: [Playlist] {
        sortAscending ? playlists : playlists.reversed()
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(sortedPlaylists) { playlist in
                    if editMode.isEditing {
                        Button {
                            renameText = playlist.name ?? ""
                            playlistToRename = playlist
                            showingRenameAlert = true
                        } label: {
                            Text(playlist.name ?? "Untitled")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .foregroundStyle(.primary)
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(value: playlist) {
                            Text(playlist.name ?? "Untitled")
                        }
                    }
                }
                .onDelete { offsets in
                    model.deletePlaylists(offsets: offsets, playlists: sortedPlaylists, context: modelContext)
                }
            }
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
            .environment(\.editMode, $editMode)
            .overlay {
                if sortedPlaylists.isEmpty {
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            sortAscending.toggle()
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(sortAscending ? Color.appPrimary : .orange)
                            .symbolRenderingMode(.hierarchical)
                            .rotationEffect(.degrees(sortAscending ? 0 : 180))
                    }
                    .accessibilityLabel(sortAscending ? "Sorted A to Z" : "Sorted Z to A")
                    .disabled(playlists.isEmpty)
                }
                ToolbarItem {
                    Button {
                        newPlaylistName = ""
                        showingNewPlaylistAlert = true
                    } label: {
                        Image(systemName: ImageConstants.add)
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
            .alert("Rename Playlist", isPresented: $showingRenameAlert, presenting: playlistToRename) { playlist in
                TextField("Name", text: $renameText)
                Button("Rename") {
                    model.renamePlaylist(playlist, name: renameText, context: modelContext)
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        .onAppear { path = NavigationPath() }
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
