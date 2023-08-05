//
//  ContentView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftUI
import SwiftData
import Awesome

struct LibraryView: View {
    @State var title: String = ""
    @State var artist: String = ""
    @State var beatsPerMinute: String = ""
    @State var beatsPerMeasure: String = ""
    @State var isPlayback: Bool = true
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var model: SongLibraryViewModel
    
    @Query private var items: [Song]

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
                        NavigationLink {
                            SongDetailsView(song: item)
                            
                        } label: {
                            VStack (alignment: .leading) {
                                Text(item.title)
                                    .bold()
                                    .font(.title3)
                                    .truncationMode(.tail)
                                    .lineLimit(1)
                                Text("\(item.artist) /  \(FormatterHelper.formatDouble(item.beatsPerMinute)) BPM")
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
                            AwesomePro.Regular.plus.image
                                .foregroundColor(.systemBlue)
                        }
                    }
                    ToolbarItem() {
                        Button(action: {
                            isPlayback = !isPlayback
                        }, label: {
                            if (isPlayback) {
                                AwesomePro.Regular.edit.image
                                    .foregroundColor(.systemBlue)
                            } else {
                                AwesomePro.Regular.play.image
                                    .foregroundColor(.systemBlue)
                            }
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
