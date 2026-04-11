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
                            SongListItemView(song: item)
                            Spacer()
                            if editMode.isEditing {
                                Button {
                                    editingSong = item
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .contentShape(Rectangle())
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(tappedId == item.id ? Color.accentColor.opacity(0.25) : Color.clear)
                                .animation(.easeOut(duration: 0.5), value: tappedId)
                        )
                        .onTapGesture {
                            guard !editMode.isEditing else { return }
                            tappedId = item.id
                            Task {
                                try? await Task.sleep(for: .seconds(0.5))
                                tappedId = nil
                            }
                            model.playSong(item)
                        }
                        
                    }
                    .onDelete(perform: editMode.isEditing ? { offsets in model.deleteItems(offsets: offsets, items: items, context: modelContext) } : nil)
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
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if (items.count > 0) {
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
                            isAddingSong = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    if metronomeViewModel.isPlaying {
                        ToolbarItem {
                            Button(action: metronomeViewModel.stop) {
                                Image(systemName: "pause")
                            }
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
        }
        .onDisappear(perform: model.stop)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = UserDefaultsService.instance.keepAwake
        }
    }
}

#Preview {
    let metronome = MetronomePlaybackViewModel()
    SongLibraryView()
        .environmentObject(SongLibraryViewModel(metronome: metronome))
        .environmentObject(metronome)
}
