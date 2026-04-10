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

    init() {
        let container = try! ModelContainer(for: Song.self)
        context = ModelContext(container)
        model = MetronomePlaybackViewModel()
    }

    init(container: ModelContainer) {
        context = ModelContext(container)
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
