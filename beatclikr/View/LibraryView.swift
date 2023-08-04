//
//  ContentView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @State var showAlert = false
    @State var title: String = ""
    @State var artist: String = ""
    @State var beatsPerMinute: String = ""
    @State var beatsPerMeasure: String = ""
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Song]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("\(item.title) by \(item.artist)")
                    } label: {
                        Text(item.title)
                            .bold()
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .alert(Text("Add a song"), isPresented: $showAlert) {
                TextField("Title", text: $title)
                TextField("Artist", text: $artist)
                TextField("Tempo (BPM)", text: $beatsPerMinute)
                    .keyboardType(.numberPad)
                TextField("Beats in a Measure", text: $beatsPerMeasure)
                    .keyboardType(.numberPad)
                Button("Save", action: addItem)
                Button("Cancel") {}
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: createNewSong) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    private func createNewSong() {
        showAlert = true
    }

    private func addItem() {
        let tempo = Int(beatsPerMinute) ?? 120
        let inAMeasure = Int(beatsPerMeasure) ?? 4
        withAnimation {
            let newItem = Song(title: self.title, artist: self.artist, beatsPerMinute: tempo, beatsPerMeasure: inAMeasure)
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: Song.self, inMemory: true)
}
