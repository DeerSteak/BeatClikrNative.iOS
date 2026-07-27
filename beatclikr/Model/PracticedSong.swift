//
//  PracticedSong.swift
//  beatclikr
//
//  Created by Ben Funk on 5/1/26.
//

import Foundation
import SwiftData

struct PracticedSongSnapshot {
    let id: String
    let title: String?
    let artist: String?
    let beatsPerMinute: Double?
    let beatsPerMeasure: Int?
    let groove: Groove?
    let timesPracticed: Int
    let durationSeconds: Double
    let songId: String?
}

@Model
final class PracticedSong: Identifiable, SongDisplayable {
    var id: String?
    var title: String?
    var artist: String?
    var beatsPerMinute: Double?
    var beatsPerMeasure: Int?
    var groove: Groove?
    var timesPracticed: Int?
    var durationSeconds: Double?
    var songId: String?

    @Relationship(inverse: \PracticeSession.songsPracticed)
    var practiceSession: PracticeSession?

    init(from song: Song) {
        id = UUID().uuidString
        title = song.title
        artist = song.artist
        beatsPerMinute = song.beatsPerMinute
        beatsPerMeasure = song.beatsPerMeasure
        groove = song.groove
        timesPracticed = 1
        durationSeconds = 0
        songId = song.id
    }

    init(title: String, artist: String, songId: String) {
        id = UUID().uuidString
        self.title = title
        self.artist = artist
        beatsPerMinute = nil
        beatsPerMeasure = nil
        groove = nil
        timesPracticed = 1
        durationSeconds = 0
        self.songId = songId
    }

    init(snapshot: PracticedSongSnapshot) {
        id = snapshot.id
        title = snapshot.title
        artist = snapshot.artist
        beatsPerMinute = snapshot.beatsPerMinute
        beatsPerMeasure = snapshot.beatsPerMeasure
        groove = snapshot.groove
        timesPracticed = snapshot.timesPracticed
        durationSeconds = snapshot.durationSeconds
        songId = snapshot.songId
    }
}
