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
    private var metronome: MetronomePlaybackViewModel
    
    init(metronome: MetronomePlaybackViewModel = MetronomePlaybackViewModel()) {
        self.metronome = metronome
    }
    
    func playSong(_ song: Song) {
        metronome.clickerType = .playlist
        metronome.switchSong(song)
        metronome.setupMetronome()
        metronome.start()
    }
    
    func stop() {
        metronome.stop()
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
