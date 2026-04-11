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
    
    @State private var showingSongPicker = false
    @State private var tappedId: String?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    if let song = entry.song {
                        if model.isPlayback {
                            SongListItemView(song: song)
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(tappedId == entry.id ? Color.accentColor.opacity(0.25) : Color.clear)
                                        .animation(.easeOut(duration: 0.5), value: tappedId)
                                )
                                .onTapGesture(perform: {
                                    if model.isPlayback {
                                        tappedId = entry.id
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            tappedId = nil
                                        }
                                        model.playSong(song)
                                    }
                                })
                        } else {
                            NavigationLink {
                                SongDetailsView(song: song)
                            } label: {
                                SongListItemView(song: song)
                            }
                        }
                    }
                }
                .onDelete { offsets in model.deleteEntries(offsets: offsets, entries: entries, context: modelContext) }
                .onMove { fromOffsets, toOffset in model.sortEntries(fromOffsets: fromOffsets, toOffset: toOffset, entries: entries) }
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
            .navigationTitle("Playlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if (entries.count > 0) {
                        MetronomePlayerView(size: MetronomeConstants.playerViewToolbarSize)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button {
                        showingSongPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem() {
                    Button(action: {
                        if model.isPlaying {
                            model.stop()
                        } else {
                            model.isPlayback = !model.isPlayback
                        }
                    }, label: {
                        Image(systemName: model.isPlayback ? (model.isPlaying ? "pause" : "play") : "square.and.pencil")
                    })
                }
            }
            .toolbarTitleDisplayMode(.automatic)
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
    }
    
}

#Preview {
    PlaylistModeView()
        .modelContainer(for: [Song.self, PlaylistEntry.self], inMemory: true)
        .environmentObject(PlaylistModeViewModel())
        .environmentObject(MetronomePlaybackViewModel())
}
