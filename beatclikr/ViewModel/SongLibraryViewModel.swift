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
    @Published var currentSongIndex: Int? = nil

    func playSong(_ song: Song, at index: Int? = nil, metronome: MetronomePlaybackViewModel) {
        metronome.clickerType = .playlist
        metronome.switchSong(song)
        metronome.setupMetronome()
        metronome.start()
        currentSongIndex = index
    }

    func playNext(items: [Song], metronome: MetronomePlaybackViewModel) {
        guard let current = currentSongIndex, current < items.count - 1 else { return }
        playSong(items[current + 1], at: current + 1, metronome: metronome)
    }

    func playPrevious(items: [Song], metronome: MetronomePlaybackViewModel) {
        guard let current = currentSongIndex, current > 0 else { return }
        playSong(items[current - 1], at: current - 1, metronome: metronome)
    }

    func canGoNext(items: [Song]) -> Bool {
        guard let current = currentSongIndex else { return false }
        return current < items.count - 1
    }

    func canGoPrevious(items: [Song]) -> Bool {
        guard let current = currentSongIndex else { return false }
        return current > 0
    }

    func playOrResume(items: [Song], metronome: MetronomePlaybackViewModel) {
        let idx = currentSongIndex ?? 0
        guard idx < items.count else { return }
        playSong(items[idx], at: idx, metronome: metronome)
    }

    func currentSongTitle(in items: [Song]) -> String? {
        guard let idx = currentSongIndex, idx < items.count else { return nil }
        return items[idx].title
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
