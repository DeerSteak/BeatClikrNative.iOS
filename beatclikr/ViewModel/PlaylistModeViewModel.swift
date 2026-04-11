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
    @Published var isPlayback: Bool = true
    @Published var isPlaying: Bool = false
    
    private var metronome: MetronomePlaybackViewModel
    private var context: ModelContext
    
    init(container: ModelContainer? = nil) {
        if let container {
            context = ModelContext(container)
        } else {
            let config = ModelConfiguration(cloudKitDatabase: .none)
            let fallback = try! ModelContainer(for: Song.self, PlaylistEntry.self, configurations: config)
            context = ModelContext(fallback)
        }
        metronome = MetronomePlaybackViewModel()
        metronome.clickerType = .playlist
    }
    
    func playSong(_ song: Song) {
        metronome.switchSong(song)
        metronome.setupMetronome()
        metronome.start()
        isPlaying = true
    }
    
    func stop() {
        metronome.stop()
        isPlaying = false
    }
    
    func addSongToPlaylist(_ song: Song, entries: [PlaylistEntry], context: ModelContext) {
        withAnimation {
            let entry = PlaylistEntry(song: song, sequence: entries.count)
            context.insert(entry)
            try! context.save()
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
            try! context.save()
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
