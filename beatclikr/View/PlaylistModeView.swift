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
    @EnvironmentObject var model: SongLibraryViewModel
    
    @Query(filter: #Predicate<Song>{$0.rehearsalSequence != nil}, sort: \Song.rehearsalSequence) private var items: [Song]
    
    var body: some View {
        VStack {
            if (items.count > 0) {
                MetronomePlayerView()
            }
            List {
                ForEach(items) { item in
                    NavigationLink {
                        SongDetailsView(song: item)
                    } label: {
                        SongListItemView(song: item)
                    }
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: sortItems)
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                items[index].rehearsalSequence = nil
                modelContext.insert(items[index])
                try! modelContext.save()
            }
        }
    }
    
    private func sortItems(fromOffsets: IndexSet, toOffset: Int) {
        var revisedItems: [Song] = items.map{ $0 }
        revisedItems.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for reverseIndex in stride (from: revisedItems.count - 1, through: 0, by: -1) {
            revisedItems[reverseIndex].rehearsalSequence = reverseIndex
        }
    }
}

#Preview {
    PlaylistModeView()
        .modelContainer(for: Song.self, inMemory: true)
        .environmentObject(SongLibraryViewModel())
}
