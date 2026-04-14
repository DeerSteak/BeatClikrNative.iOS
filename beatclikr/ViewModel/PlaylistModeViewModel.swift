//
//  PlaylistModeViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 4/11/26.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class PlaylistModeViewModel : ObservableObject {
    @Published var currentSongIndex: Int?
    
    func playSong(_ song: Song, at index: Int? = nil, metronome: MetronomePlaybackViewModel) {
        print("🎵 PlaylistModeViewModel.playSong - Setting index to: \(String(describing: index)), song: \(song.title ?? "nil")")
        metronome.clickerType = .playlist
        metronome.switchSong(song)
        metronome.setupMetronome()
        metronome.start()
        currentSongIndex = index
    }
    
    func playNext(entries: [PlaylistEntry], metronome: MetronomePlaybackViewModel) {
        print("⏭️ PlaylistModeViewModel.playNext - currentIndex: \(String(describing: currentSongIndex)), entries.count: \(entries.count)")
        guard let currentIndex = currentSongIndex, currentIndex < entries.count - 1 else {
            return
        }
        let nextEntry = entries[currentIndex + 1]
        if let song = nextEntry.song {
            playSong(song, at: currentIndex + 1, metronome: metronome)
        }
    }
    
    func playPrevious(entries: [PlaylistEntry], metronome: MetronomePlaybackViewModel) {
        guard let currentIndex = currentSongIndex, currentIndex > 0 else {
            return
        }
        let previousEntry = entries[currentIndex - 1]
        if let song = previousEntry.song {
            playSong(song, at: currentIndex - 1, metronome: metronome)
        }
    }
    
    func canGoNext(entries: [PlaylistEntry]) -> Bool {
        guard let currentIndex = currentSongIndex else { return false }
        return currentIndex < entries.count - 1
    }
    
    func canGoPrevious(entries: [PlaylistEntry]) -> Bool {
        guard let currentIndex = currentSongIndex else { return false }
        return currentIndex > 0
    }
    
    func addSongToPlaylist(_ song: Song, entries: [PlaylistEntry], context: ModelContext) {
        withAnimation {
            let entry = PlaylistEntry(song: song, sequence: entries.count)
            context.insert(entry)
            do {
                try context.save()
            } catch {
                print("Failed to add song to playlist: \(error)")
            }
        }
    }
    
    func deleteEntries(offsets: IndexSet, entries: [PlaylistEntry], context: ModelContext) {
        withAnimation {
            for index in offsets {
                context.delete(entries[index])
            }
            let remaining = entries.enumerated().filter { !offsets.contains($0.offset) }
            for (newIndex, element) in remaining.enumerated() {
                element.element.sequence = newIndex
            }
            do {
                try context.save()
            } catch {
                print("Failed to delete playlist entries: \(error)")
            }
        }
    }
    
    func sortEntries(fromOffsets: IndexSet, toOffset: Int, entries: [PlaylistEntry]) {
        var revisedEntries = entries.map { $0 }
        revisedEntries.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (index, entry) in revisedEntries.enumerated() {
            entry.sequence = index
        }
    }
}
