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
    
    private var metronome: MetronomePlaybackViewModel
    
    init(metronome: MetronomePlaybackViewModel = MetronomePlaybackViewModel()) {
        self.metronome = metronome
    }
    
    func playSong(_ song: Song) {
        metronome.clickerType = .playlist
        metronome.switchSong(song)
        metronome.setupMetronome()
        metronome.start()
        isPlaying = true
    }
    
    func stop() {
        metronome.stop()
        isPlaying = false
    }
    
    func deleteItems(offsets: IndexSet, items: [Song], context: ModelContext) {
        withAnimation {
            for index in offsets {
                context.delete(items[index])
            }
            do {
                try context.save()
            } catch {
                print("Failed to delete songs: \(error)")
            }
        }
    }
}
