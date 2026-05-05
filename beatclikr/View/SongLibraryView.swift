//
//  ContentView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftUI
import SwiftData

struct SongLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var model: SongLibraryViewModel
    @EnvironmentObject var metronomeViewModel: MetronomePlaybackViewModel
    @EnvironmentObject var practiceHistory: PracticeHistoryViewModel
    @Query(sort: [SortDescriptor(\Song.title), SortDescriptor(\Song.artist)]) private var items: [Song]

    @State private var editMode: EditMode = .inactive
    @State private var tappedId: String?
    @State private var isAddingSong = false
    @State private var editingSong: Song?

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            if editMode.isEditing {
                                Button {
                                    model.deleteItems(offsets: IndexSet([index]), items: items, context: modelContext)
                                } label: {
                                    Image(systemName: ImageConstants.removeCircle)
                                        .foregroundStyle(.red)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Delete \(item.title ?? "song")")
                                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
                            }
                            Button {
                                guard !editMode.isEditing else { return }
                                tappedId = item.id
                                Task {
                                    try? await Task.sleep(for: .seconds(0.5))
                                    tappedId = nil
                                }
                                model.playSong(item, metronome: metronomeViewModel)
                            } label: {
                                HStack {
                                    Image(systemName: ImageConstants.play)
                                        .foregroundColor(.appPrimary)
                                        .font(.caption)
                                        .accessibilityHidden(true)
                                        .opacity(model.currentIndex(in: items) == index ? 1 : 0)
                                    SongListItemView(song: item)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(editMode.isEditing)
                            if editMode.isEditing {
                                Button {
                                    editingSong = item
                                } label: {
                                    Image(systemName: ImageConstants.edit)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Edit \(item.title ?? "song")")
                                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .trailing)))
                            }
                        }
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .listRowBackground(
                            ZStack {
                                Color(UIColor.systemBackground)
                                Color.appPrimary.opacity(tappedId == item.id ? 0.25 : 0)
                                    .animation(.easeOut(duration: 0.5), value: tappedId)
                            }
                        )
                    }
                }
                .environment(\.editMode, $editMode)
                .overlay(content: {
                    if (items.isEmpty) {
                        VStack {
                            Text("Press the + button to add a song")
                                .padding(.top, 40)
                            Spacer()
                        }
                    }
                })
                .safeAreaInset(edge: .bottom) {
                    if !editMode.isEditing && !items.isEmpty {
                        PlaylistTransportView(
                            currentTitle: model.currentSongTitle(in: items),
                            onPlay: { model.playOrResume(items: items, metronome: metronomeViewModel) },
                            canGoPrevious: model.canGoPrevious(items: items),
                            onPrevious: { model.playPrevious(items: items, metronome: metronomeViewModel) },
                            canGoNext: model.canGoNext(items: items),
                            onNext: { model.playNext(items: items, metronome: metronomeViewModel) }
                        )
                    }
                }
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
                            isAddingSong = true
                        } label: {
                            Image(systemName: ImageConstants.add)
                        }
                        .accessibilityLabel("Add Song")
                    }
                }
                .sheet(isPresented: $isAddingSong) {
                    SongDetailsView()
                }
                .sheet(item: $editingSong) { song in
                    SongDetailsView(song: song)
                }
                .toolbarTitleDisplayMode(.automatic)
                .navigationTitle("Song Library")
                .navigationBarTitleDisplayMode(.automatic)
                .onChange(of: model.currentSongId) { _, _ in
                    if let newIndex = model.currentIndex(in: items), newIndex < items.count {
                        withAnimation {
                            proxy.scrollTo(items[newIndex].id, anchor: .center)
                        }
                    }
                }
            }
        }
        .onDisappear(perform: metronomeViewModel.stop)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = UserDefaultsService.instance.keepAwake
            model.onSongPlayed = { song in
                practiceHistory.recordSongPlayed(song: song, context: modelContext)
            }
        }
    }
}

#Preview {
    let preview = PreviewContainer([Song.self, PlaylistEntry.self])
    preview.addMockSongs()

    return SongLibraryView()
        .modelContainer(preview.container)
        .environmentObject(SongLibraryViewModel())
        .environmentObject(MetronomePlaybackViewModel())
        .environmentObject(PracticeHistoryViewModel())
}
