//
//  PreviewDataContainer.swift
//  beatclikr
//
//  Created by Ben Funk on 10/12/23.
//

import Foundation
import SwiftData

struct PreviewContainer {
    let container: ModelContainer!
    
    init(_ types: [any PersistentModel.Type], isStoredInMemoryOnly: Bool = true) {
        let schema = Schema(types)
        let config = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
        self.container = try! ModelContainer(for: schema, configurations: [config])
    }
    
    /// Inserts mock songs and returns them for further use (e.g. building playlist entries).
    @MainActor
    @discardableResult
    func addMockSongs() -> [Song] {
        let songs: [Song] = [
            makeSong("Bohemian Rhapsody", artist: "Queen", bpm: 72),
            makeSong("Sweet Child O' Mine", artist: "Guns N' Roses", bpm: 125),
            makeSong("Stairway to Heaven", artist: "Led Zeppelin", bpm: 82),
            makeSong("Hotel California", artist: "Eagles", bpm: 74),
        ]
        songs.forEach { container.mainContext.insert($0) }
        return songs
    }
    
    /// Inserts playlist entries for each song in order.
    @MainActor
    func addMockPlaylistEntries(for songs: [Song]) {
        for (index, song) in songs.enumerated() {
            container.mainContext.insert(PlaylistEntry(song: song, sequence: index))
        }
    }
    
    /// Creates a named playlist with entries for the given songs and returns it.
    @MainActor
    @discardableResult
    func addMockPlaylist(named name: String, songs: [Song]) -> Playlist {
        let playlist = Playlist(name: name)
        container.mainContext.insert(playlist)
        for (index, song) in songs.enumerated() {
            let entry = PlaylistEntry(song: song, sequence: index)
            entry.playlist = playlist
            container.mainContext.insert(entry)
        }
        return playlist
    }
    
    // MARK: - Private
    private func makeSong(_ title: String, artist: String, bpm: Double) -> Song {
        let song = Song()
        song.title = title
        song.artist = artist
        song.beatsPerMinute = bpm
        return song
    }
}
