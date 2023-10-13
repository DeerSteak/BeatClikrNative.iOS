//
//  ContentView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var model: SongLibraryViewModel
    
    @Query(sort: [SortDescriptor(\Song.title), SortDescriptor(\Song.artist)]) private var items: [Song]
    
    var body: some View {
        NavigationSplitView {
            VStack {
                if (items.count > 0) {
                    MetronomePlayerView()
                }
                List {
                    ForEach(items.sorted(by: { a, b in
                        a.title < b.title
                    })) { item in
                        if (model.isPlayback) {
                            SongListItemView(song: item)
                                .onTapGesture(perform: {
                                    if model.isPlayback {
                                        playSong(item)
                                    }
                                })
                        } else {
                            NavigationLink {
                                SongDetailsView(song: item)
                            } label: {
                                SongListItemView(song: item)
                            }
                        }
                        
                    }
                    .onDelete(perform: deleteItems)
                }
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
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        NavigationLink(destination: SongDetailsView()) {
                            Image(systemName: "plus")
                        }
                    }
                    ToolbarItem() {
                        Button(action: {
                            if model.isPlaying {
                                stop()
                            } else {
                                model.isPlayback = !model.isPlayback
                            }
                        }, label: {
                            Image(systemName: model.isPlayback ? (model.isPlaying ? "pause" : "play") : "square.and.pencil")
                        })
                    }
                }
                .toolbarTitleDisplayMode(.automatic)
                .navigationTitle("Song Library")
            }
        } detail: {
            Text("Select an item")
        }
        .onDisappear(perform: model.stopMetronome)
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
                try! modelContext.save()
            }
        }
    }
    
    private func stop() {
        model.stopMetronome()
        model.isPlaying = false
    }
    
    private func playSong(_ song: Song) {
        model.switchSong(song)
        model.startMetronome()
        model.isPlaying = true
    }
}

#Preview {
    let previewContainer = PreviewContainer([Song.self])
    let vm = SongLibraryViewModel(container: previewContainer.container)
    return LibraryView()
        .environmentObject(vm)
}
