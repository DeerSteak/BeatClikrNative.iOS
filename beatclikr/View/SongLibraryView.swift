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
    @Query(sort: [SortDescriptor(\Song.title), SortDescriptor(\Song.artist)]) private var items: [Song]
    
    @State private var editMode: EditMode = .inactive
    @State private var tappedId: String?
    @State private var isAddingSong = false
    @State private var editingSong: Song?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                        HStack {
                            if editMode.isEditing {
                                Button {
                                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                                        model.deleteItems(offsets: IndexSet([index]), items: items, context: modelContext)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
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
                                SongListItemView(song: item)
                            }
                            .buttonStyle(.plain)
                            .disabled(editMode.isEditing)
                            Spacer()
                            if editMode.isEditing {
                                Button {
                                    editingSong = item
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Edit \(item.title ?? "song")")
                                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .trailing)))
                            }
                        }
                        .contentShape(Rectangle())
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(tappedId == item.id ? Color.accentColor.opacity(0.25) : Color.clear)
                                .animation(.easeOut(duration: 0.5), value: tappedId)
                        )

                    }
                }
                .environment(\.editMode, $editMode)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.systemGroupedBackground))
                .overlay(content: {
                    if (items.isEmpty) {
                        VStack {
                            Text("Press the + button to add a song")
                                .padding(.top, 40)
                            Spacer()
                        }
                    }
                })
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if (items.count > 0) {
                            MetronomePlayerView(size: MetronomeConstants.playerViewToolbarSize)
                        }
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
                            isAddingSong = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add Song")
                    }
                    if metronomeViewModel.isPlaying {
                        ToolbarItem {
                            Button(action: metronomeViewModel.stop) {
                                Image(systemName: "pause")
                            }
                            .accessibilityLabel("Stop Metronome")
                        }
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
        }
        .onDisappear(perform: metronomeViewModel.stop)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = UserDefaultsService.instance.keepAwake
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
}
