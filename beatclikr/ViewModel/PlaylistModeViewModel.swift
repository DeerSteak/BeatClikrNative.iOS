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
        guard let currentIndex = currentSongIndex, currentIndex + 1 < entries.count else { return }
        if let nextIdx = ((currentIndex + 1)..<entries.count).first(where: { entries[$0].song != nil }),
           let song = entries[nextIdx].song {
            playSong(song, at: nextIdx, metronome: metronome)
        }
    }
    
    func playPrevious(entries: [PlaylistEntry], metronome: MetronomePlaybackViewModel) {
        guard let currentIndex = currentSongIndex, currentIndex > 0 else { return }
        if let prevIdx = (0..<currentIndex).reversed().first(where: { entries[$0].song != nil }),
           let song = entries[prevIdx].song {
            playSong(song, at: prevIdx, metronome: metronome)
        }
    }
    
    func canGoNext(entries: [PlaylistEntry]) -> Bool {
        guard let currentIndex = currentSongIndex, currentIndex + 1 < entries.count else { return false }
        return ((currentIndex + 1)..<entries.count).contains { $0 < entries.count && entries[$0].song != nil }
    }
    
    func canGoPrevious(entries: [PlaylistEntry]) -> Bool {
        guard let currentIndex = currentSongIndex, currentIndex > 0 else { return false }
        return (0..<currentIndex).contains { entries[$0].song != nil }
    }
    
    func playOrResume(entries: [PlaylistEntry], metronome: MetronomePlaybackViewModel) {
        if let idx = currentSongIndex, idx < entries.count, let song = entries[idx].song {
            playSong(song, at: idx, metronome: metronome)
        } else if let firstIdx = entries.indices.first(where: { entries[$0].song != nil }),
                  let song = entries[firstIdx].song {
            playSong(song, at: firstIdx, metronome: metronome)
        }
    }
    
    func currentSongTitle(in entries: [PlaylistEntry]) -> String? {
        guard let idx = currentSongIndex, idx < entries.count else { return nil }
        return entries[idx].song?.title
    }
    
    func addSongToPlaylist(_ song: Song, playlist: Playlist, context: ModelContext) {
        withAnimation {
            let entry = PlaylistEntry(song: song, sequence: (playlist.entries ?? []).count)
            entry.playlist = playlist
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
