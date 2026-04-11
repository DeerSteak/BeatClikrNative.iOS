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
    @Published var isPlayback: Bool = true
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
    }
    
    func switchSong(_ song: Song) {
        model.switchSong(song)
    }
    
    func startMetronome() {
        model.setupMetronome()
        model.start()
    }
    
    func stopMetronome() {
        model.stop()
    }
}
