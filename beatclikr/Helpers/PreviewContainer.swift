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
    
    /// Inserts practice sessions for several recent days with mock songs.
    @MainActor
    func addMockPracticeHistory() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let sessionData: [(daysAgo: Int, songs: [(String, String, Double)])] = [
            (0, [("Bohemian Rhapsody", "Queen", 72), ("Hotel California", "Eagles", 74)]),
            (1, [("Sweet Child O' Mine", "Guns N' Roses", 125)]),
            (3, [("Stairway to Heaven", "Led Zeppelin", 82), ("Black Dog", "Led Zeppelin", 92)]),
            (5, [("Roxanne", "The Police", 130)]),
            (8, [("Come As You Are", "Nirvana", 120), ("Smells Like Teen Spirit", "Nirvana", 116), ("In Bloom", "Nirvana", 110)]),
            (12, [("Yellow", "Coldplay", 88)]),
        ]
        for entry in sessionData {
            let date = cal.date(byAdding: .day, value: -entry.daysAgo, to: today)!
            let session = PracticeSession(date: date)
            let practiced = entry.songs.map { title, artist, bpm -> PracticedSong in
                let song = makeSong(title, artist: artist, bpm: bpm)
                return PracticedSong(from: song)
            }
            practiced.forEach { container.mainContext.insert($0) }
            session.songsPracticed = practiced
            container.mainContext.insert(session)
        }
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
