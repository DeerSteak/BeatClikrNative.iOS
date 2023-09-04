//
//  ContentView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @State var title: String = ""
    @State var artist: String = ""
    @State var beatsPerMinute: String = ""
    @State var beatsPerMeasure: String = ""
    @State var isPlayback: Bool = true
    @State var tada: Bool = false
    
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
                        if (isPlayback) {
                            SongListItemView(song: item)
                                .onTapGesture(perform: {
                                    tada = true
                                })
                                .alert("Thingy", isPresented: $tada) {
                                    Button("Thanks!") {
                                        tada = false
                                    }
                                }
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
                            isPlayback = !isPlayback
                        }, label: {
                            Image(systemName: isPlayback ? "play" : "square.and.pencil")
                        })
                    }
                }
                .toolbarTitleDisplayMode(.automatic)
                .navigationTitle("Song Library")
            }
        } detail: {
            Text("Select an item")
        }      
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
                try! modelContext.save()
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: Song.self, inMemory: true)
        .environmentObject(MetronomePlaybackViewModel())
}
