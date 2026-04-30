//
//  PlaylistDetailView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/7/23.
//

import SwiftUI
import SwiftData

struct PlaylistDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var metronome: MetronomePlaybackViewModel
    @StateObject private var model = PlaylistDetailViewModel()

    let playlist: Playlist

    @State private var editMode: EditMode = .inactive
    @State private var showingSongPicker = false
    @State private var tappedId: String?
    @State private var editingSong: Song?

    @ViewBuilder
    private func playlistRow(for song: Song, entry: PlaylistEntry, at index: Int, in entries: [PlaylistEntry]) -> some View {
        HStack {
            if editMode.isEditing {
                Button {
                    if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
                        model.deleteEntries(offsets: IndexSet([idx]), entries: entries, context: modelContext)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
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
                model.playSong(song, at: index, metronome: metronome)
            } label: {
                HStack {
                    if model.currentSongIndex == index {
                        Image(systemName: "play.fill")
                            .foregroundColor(.appPrimary)
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
                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .trailing)))
            }
        }
        .contentShape(Rectangle())
        .listRowBackground(rowBackground(for: entry, at: index))
    }

    @ViewBuilder
    private func rowBackground(for entry: PlaylistEntry, at index: Int) -> some View {
        let backgroundColor: Color = {
            if tappedId == entry.id {
                return Color.appPrimary.opacity(0.25)
            } else if model.currentSongIndex == index {
                return Color.appPrimary.opacity(0.1)
            } else {
                return Color.clear
            }
        }()
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
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
                        model.sortEntries(fromOffsets: fromOffsets, toOffset: toOffset, entries: entries)
                    }
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
                    PlaylistTransportView(
                        currentTitle: model.currentSongTitle(in: entries),
                        onPlay: { model.playOrResume(items: entries, metronome: metronome) },
                        canGoPrevious: model.canGoPrevious(items: entries),
                        onPrevious: { model.playPrevious(items: entries, metronome: metronome) },
                        canGoNext: model.canGoNext(items: entries),
                        onNext: { model.playNext(items: entries, metronome: metronome) }
                    )
                }
            }
            .navigationTitle(playlist.name ?? "Playlist")
            .toolbar {
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
                SongPickerView(playlist: playlist)
                    .environmentObject(model)
            }
        }
        .onDisappear(perform: metronome.stop)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = UserDefaultsService.instance.keepAwake
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
}
