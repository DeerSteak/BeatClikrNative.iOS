//
//  PlaylistDetailView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/7/23.
//

import SwiftData
import SwiftUI

struct PlaylistDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var metronome: MetronomePlaybackViewModel
    @EnvironmentObject var practiceHistory: PracticeHistoryViewModel
    @StateObject private var model = PlaylistDetailViewModel()

    let playlist: Playlist

    @State private var editMode: EditMode = .inactive
    @State private var showingSongPicker = false
    @State private var showingFocusView = false
    @State private var editingSong: Song?
    @State private var tappedId: String?

    private func playlistRow(for song: Song, entry: PlaylistEntry, at index: Int, in entries: [PlaylistEntry]) -> some View {
        HStack {
            if editMode.isEditing {
                Button {
                    if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
                        model.deleteEntries(offsets: IndexSet([idx]), entries: entries, context: modelContext)
                    }
                } label: {
                    Image(systemName: ImageConstants.removeCircle)
                        .foregroundStyle(.red)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(song.title ?? "song")")
                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
            }
            Button {
                guard !editMode.isEditing else { return }
                tappedId = entry.id
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    tappedId = nil
                }
                model.playSong(song, metronome: metronome)
            } label: {
                HStack {
                    Image(systemName: ImageConstants.play)
                        .foregroundColor(.appPrimary)
                        .font(.caption)
                        .opacity(model.currentIndex(in: entries) == index ? 1 : 0)
                    SongListItemView(song: song)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(editMode.isEditing)

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
                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .trailing)))
            }
        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .listRowBackground(
            ZStack {
                Color(UIColor.systemBackground)
                Color.appPrimary.opacity(tappedId == entry.id ? 0.25 : 0)
                    .animation(.easeOut(duration: 0.5), value: tappedId)
            },
        )
    }

    var body: some View {
        let entries = (playlist.entries ?? []).sorted { ($0.sequence ?? 0) < ($1.sequence ?? 0) }
        ScrollViewReader { proxy in
            List {
                Section {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        if let song = entry.song {
                            playlistRow(for: song, entry: entry, at: index, in: entries)
                        }
                    }
                    .onMove { fromOffsets, toOffset in
                        model.sortEntries(fromOffsets: fromOffsets, toOffset: toOffset, entries: entries, context: modelContext)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
            .environment(\.editMode, $editMode)
            .onChange(of: model.currentSongId) { _, _ in
                if let idx = model.currentIndex(in: entries), idx < entries.count {
                    withAnimation {
                        proxy.scrollTo(entries[idx].id, anchor: .center)
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
                if !editMode.isEditing, !entries.isEmpty {
                    PlaylistTransportView(
                        currentTitle: model.currentSongTitle(in: entries),
                        onPlay: { model.playOrResume(items: entries, metronome: metronome) },
                        canGoPrevious: model.canGoPrevious(items: entries),
                        onPrevious: { model.playPrevious(items: entries, metronome: metronome) },
                        canGoNext: model.canGoNext(items: entries),
                        onNext: { model.playNext(items: entries, metronome: metronome) },
                    )
                }
            }
            .navigationTitle(playlist.name ?? "Playlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingFocusView = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                    .accessibilityLabel("Focus View")
                    .opacity(editMode.isEditing || entries.isEmpty ? 0 : 1)
                    .disabled(editMode.isEditing || entries.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editMode.isEditing ? "Done" : "Edit") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
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
            }
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(item: $editingSong) { song in
                SongDetailsView(song: song)
            }
            .fullScreenCover(isPresented: $showingFocusView) {
                PlaylistFocusView(
                    model: model,
                    entries: entries,
                    onDismiss: { showingFocusView = false },
                )
                .environmentObject(metronome)
            }
            .sheet(isPresented: $showingSongPicker) {
                SongPickerView(playlist: playlist)
                    .environmentObject(model)
            }
        }
        .onDisappear {
            metronome.stop()
            model.onDisappear()
        }
        .onAppear {
            model.onAppear()
            model.onSongPlayed = { song in
                practiceHistory.recordSongPlayed(song: song, context: modelContext)
            }
        }
    }
}

#Preview {
    let preview = PreviewContainer([Song.self, PlaylistEntry.self, Playlist.self])
    let songs = preview.addMockSongs()
    let playlist = preview.addMockPlaylist(named: "My Playlist", songs: songs)

    return NavigationStack {
        PlaylistDetailView(playlist: playlist)
    }
    .modelContainer(preview.container)
    .environmentObject(MetronomePlaybackViewModel())
    .environmentObject(PracticeHistoryViewModel())
}
