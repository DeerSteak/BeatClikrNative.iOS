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
    @EnvironmentObject var metronome: MetronomePlaybackViewModel
    @Query(sort: \PlaylistEntry.sequence) private var entries: [PlaylistEntry]
    @Query(sort: [SortDescriptor(\Song.title), SortDescriptor(\Song.artist)]) private var allSongs: [Song]
    
    @State private var editMode: EditMode = .inactive
    @State private var showingSongPicker = false
    @State private var tappedId: String?
    @State private var editingSong: Song?
    
    // Helper function to create a playlist row
    @ViewBuilder
    private func playlistRow(for song: Song, entry: PlaylistEntry, at index: Int) -> some View {
        HStack {
            Button {
                guard !editMode.isEditing else { return }
                tappedId = entry.id
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    tappedId = nil
                }
                model.playSong(song, at: index, metronome: metronome)
            } label: {
                HStack {
                    // Play indicator
                    if model.currentSongIndex == index {
                        Image(systemName: "play.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                    }
                    SongListItemView(song: song)
                }
            }
            .buttonStyle(.plain)
            .disabled(editMode.isEditing)
            
            Spacer()
            
            if editMode.isEditing {
                Button {
                    editingSong = song
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                .accessibilityLabel("Edit \(song.title ?? "song")")
            }
        }
        .contentShape(Rectangle())
        .listRowBackground(rowBackground(for: entry, at: index))
    }
    
    // Helper function to create the row background
    @ViewBuilder
    private func rowBackground(for entry: PlaylistEntry, at index: Int) -> some View {
        let backgroundColor: Color = {
            if tappedId == entry.id {
                return Color.accentColor.opacity(0.25)
            } else if model.currentSongIndex == index {
                return Color.accentColor.opacity(0.1)
            } else {
                return Color.clear
            }
        }()
        
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    // Song entries
                    Section {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            if let song = entry.song {
                                playlistRow(for: song, entry: entry, at: index)
                            }
                        }
                        .onDelete(perform: editMode.isEditing ? { offsets in model.deleteEntries(offsets: offsets, entries: entries, context: modelContext) } : nil)
                        .onMove { fromOffsets, toOffset in model.sortEntries(fromOffsets: fromOffsets, toOffset: toOffset, entries: entries) }
                    }
                }
                .environment(\.editMode, $editMode)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.systemGroupedBackground))
                .onChange(of: model.currentSongIndex) { _, newIndex in
                    if let newIndex, newIndex < entries.count {
                        withAnimation {
                            proxy.scrollTo(entries[newIndex].id, anchor: .center)
                        }
                    }
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
                .safeAreaInset(edge: .bottom) {
                    if !editMode.isEditing && !entries.isEmpty {
                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                // Previous button
                                Button {
                                    model.playPrevious(entries: entries, metronome: metronome)
                                } label: {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        Text("Previous")
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(model.canGoPrevious(entries: entries) ? Color.accentColor : Color.secondary.opacity(0.3))
                                    )
                                    .foregroundStyle(.white)
                                }
                                .disabled(!model.canGoPrevious(entries: entries))
                                .accessibilityLabel("Previous Song")
                                
                                Button(action: metronome.stop) {
                                    Image(systemName: "pause.fill")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .frame(width: 56, height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(metronome.isPlaying ? Color.accentColor : Color.secondary.opacity(0.3))
                                        )
                                        .foregroundStyle(.white)
                                }
                                .accessibilityLabel("Stop Metronome")
                                .disabled(!metronome.isPlaying)
                                
                                Button {
                                    model.playNext(entries: entries, metronome: metronome)
                                } label: {
                                    HStack {
                                        Text("Next")
                                            .font(.headline)
                                        Image(systemName: "chevron.right")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(model.canGoNext(entries: entries) ? Color.accentColor : Color.secondary.opacity(0.3))
                                    )
                                    .foregroundStyle(.white)
                                }
                                .disabled(!model.canGoNext(entries: entries))
                                .accessibilityLabel("Next Song")
                            }
                            .padding(.horizontal, 16)
                            
                            // Current song indicator
                            VStack(spacing: 4) {
                                if let currentIndex = model.currentSongIndex,
                                   currentIndex < entries.count,
                                   let currentSong = entries[currentIndex].song {
                                    Text("Now Playing")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(currentSong.title ?? "Untitled")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                } else {
                                    Text("Tap a song to begin")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("--")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .padding(.vertical, 12)
                        .background(.regularMaterial)
                        .overlay {
                            Color.accentColor
                                .opacity(metronome.isPlaying ? metronome.beatPulse * 0.35 : 0)
                                .allowsHitTesting(false)
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
                        .accessibilityLabel("Add Song to Playlist")
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
            .onDisappear(perform: metronome.stop)
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = UserDefaultsService.instance.keepAwake
            }
        }
    }
}
    
    #Preview {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Song.self, PlaylistEntry.self, configurations: config)
        
        // Create mock songs
        let song1 = Song()
        song1.title = "Bohemian Rhapsody"
        song1.artist = "Queen"
        song1.beatsPerMinute = 72
        
        let song2 = Song()
        song2.title = "Sweet Child O' Mine"
        song2.artist = "Guns N' Roses"
        song2.beatsPerMinute = 125
        
        let song3 = Song()
        song3.title = "Stairway to Heaven"
        song3.artist = "Led Zeppelin"
        song3.beatsPerMinute = 82
        
        let song4 = Song()
        song4.title = "Hotel California"
        song4.artist = "Eagles"
        song4.beatsPerMinute = 74
        
        container.mainContext.insert(song1)
        container.mainContext.insert(song2)
        container.mainContext.insert(song3)
        container.mainContext.insert(song4)
        
        // Create playlist entries
        let entry1 = PlaylistEntry(song: song1, sequence: 0)
        let entry2 = PlaylistEntry(song: song2, sequence: 1)
        let entry3 = PlaylistEntry(song: song3, sequence: 2)
        let entry4 = PlaylistEntry(song: song4, sequence: 3)
        
        container.mainContext.insert(entry1)
        container.mainContext.insert(entry2)
        container.mainContext.insert(entry3)
        container.mainContext.insert(entry4)
        
        return PlaylistModeView()
            .modelContainer(container)
            .environmentObject(PlaylistModeViewModel())
            .environmentObject(MetronomePlaybackViewModel())
    }
