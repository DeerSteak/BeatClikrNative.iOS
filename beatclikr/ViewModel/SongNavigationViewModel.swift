//
//  SongNavigationViewModel.swift
//  beatclikr
//

import Foundation
import SwiftUI

// Abstracts over Song (song = self) and PlaylistEntry (song = optional relationship),
// allowing the same navigation logic to work for both.
protocol SongNavigatable {
    var song: Song? { get }
}

extension Song: SongNavigatable {
    var song: Song? { self }
}

extension PlaylistEntry: SongNavigatable {}

// Base class shared by SongLibraryViewModel and PlaylistDetailViewModel.
// Tracks position in a list and drives playback navigation.
@MainActor
class SongNavigationViewModel: ObservableObject {
    @Published var currentSongId: String?
    
    var onSongPlayed: ((Song) -> Void)?

    func playSong(_ song: Song, metronome: MetronomePlaybackViewModel) {
        metronome.clickerType = .playlist
        metronome.switchSong(song)
        metronome.setupMetronome()
        metronome.start()
        currentSongId = song.id
        onSongPlayed?(song)
    }

    // Derives the current position from identity rather than storing a raw index,
    // so deletions and re-sorts can't cause drift.
    func currentIndex<T: SongNavigatable>(in items: [T]) -> Int? {
        guard let id = currentSongId else { return nil }
        return items.firstIndex { $0.song?.id == id }
    }

    func playNext<T: SongNavigatable>(items: [T], metronome: MetronomePlaybackViewModel) {
        guard let current = currentIndex(in: items) else { return }
        if let nextIdx = ((current + 1)..<items.count).first(where: { items[$0].song != nil }),
           let song = items[nextIdx].song {
            playSong(song, metronome: metronome)
        }
    }

    func playPrevious<T: SongNavigatable>(items: [T], metronome: MetronomePlaybackViewModel) {
        guard let current = currentIndex(in: items), current > 0 else { return }
        if let prevIdx = (0..<current).reversed().first(where: { items[$0].song != nil }),
           let song = items[prevIdx].song {
            playSong(song, metronome: metronome)
        }
    }

    func canGoNext<T: SongNavigatable>(items: [T]) -> Bool {
        guard let current = currentIndex(in: items) else { return false }
        return ((current + 1)..<items.count).contains { items[$0].song != nil }
    }

    func canGoPrevious<T: SongNavigatable>(items: [T]) -> Bool {
        guard let current = currentIndex(in: items), current > 0 else { return false }
        return (0..<current).contains { items[$0].song != nil }
    }

    func playOrResume<T: SongNavigatable>(items: [T], metronome: MetronomePlaybackViewModel) {
        if let idx = currentIndex(in: items), let song = items[idx].song {
            playSong(song, metronome: metronome)
        } else if let firstIdx = items.indices.first(where: { items[$0].song != nil }),
                  let song = items[firstIdx].song {
            playSong(song, metronome: metronome)
        }
    }

    func currentSongTitle<T: SongNavigatable>(in items: [T]) -> String? {
        guard let idx = currentIndex(in: items) else { return nil }
        return items[idx].song?.title
    }
}
