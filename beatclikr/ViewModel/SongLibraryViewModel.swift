//
//  SongLibraryViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class SongLibraryViewModel : ObservableObject {
    @Published var isPlaying: Bool = false
    
    private var model: MetronomePlaybackViewModel
    private var context: ModelContext
    
    init(container: ModelContainer? = nil) {
        if let container {
            context = ModelContext(container)
        } else {
            let config = ModelConfiguration(cloudKitDatabase: .none)
            let fallback = try! ModelContainer(for: Song.self, PlaylistEntry.self, configurations: config)
            context = ModelContext(fallback)
        }
        model = MetronomePlaybackViewModel()
        model.clickerType = .playlist
    }
    
    func playSong(_ song: Song) {
        model.switchSong(song)
        model.setupMetronome()
        model.start()
        isPlaying = true
    }
    
    func stop() {
        model.stop()
        isPlaying = false
    }
    
    func deleteItems(offsets: IndexSet, items: [Song], context: ModelContext) {
        withAnimation {
            for index in offsets {
                context.delete(items[index])
            }
            try! context.save()
        }
    }
}
