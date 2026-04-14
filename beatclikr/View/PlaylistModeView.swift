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
    @EnvironmentObject var metronomeViewModel: MetronomePlaybackViewModel
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
                            Button {
                                guard !editMode.isEditing else { return }
                                tappedId = entry.id
                                Task {
                                    try? await Task.sleep(for: .seconds(0.5))
                                    tappedId = nil
                                }
                                model.playSong(song)
                            } label: {
                                SongListItemView(song: song)
                            }
                            .buttonStyle(.plain)
                            .disabled(editMode.isEditing)
                            Spacer()
                            if editMode.isEditing {
                                Button {
                                    editingSong = song
                                } label: {
                                    Image(systemName: ImageConstants.edit)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 8)
                                .accessibilityLabel("Edit \(song.title ?? "song")")
                            }
                        }
                        .contentShape(Rectangle())
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(tappedId == entry.id ? Color.accentColor.opacity(0.25) : Color.clear)
                                .animation(.easeOut(duration: 0.5), value: tappedId)
                        )
                    }
                }
                .onDelete(perform: editMode.isEditing ? { offsets in model.deleteEntries(offsets: offsets, entries: entries, context: modelContext) } : nil)
                .onMove { fromOffsets, toOffset in model.sortEntries(fromOffsets: fromOffsets, toOffset: toOffset, entries: entries) }
            }
            .environment(\.editMode, $editMode)
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
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
                        Image(systemName: ImageConstants.add)
                    }
                    .accessibilityLabel("Add Song to Playlist")
                }
                if metronomeViewModel.isPlaying {
                    ToolbarItem {
                        Button(action: metronomeViewModel.stop) {
                            Image(systemName: ImageConstants.pause)
                        }
                        .accessibilityLabel("Stop Metronome")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.automatic)
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
                    .navigationBarTitleDisplayMode(.inline)
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
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = UserDefaultsService.instance.keepAwake
        }
    }
}

#Preview {
    PlaylistModeView()
        .modelContainer(for: [Song.self, PlaylistEntry.self], inMemory: true)
        .environmentObject(PlaylistModeViewModel())
        .environmentObject(MetronomePlaybackViewModel())
}
