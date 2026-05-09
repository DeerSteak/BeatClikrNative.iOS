//
//  PracticedSong.swift
//  beatclikr
//
//  Created by Ben Funk on 5/1/26.
//

import Foundation
import SwiftData

@Model
final class PracticedSong: Identifiable, SongDisplayable {
    var id: String?
    var title: String?
    var artist: String?
    var beatsPerMinute: Double?
    var beatsPerMeasure: Int?
    var groove: Groove?
    var timesPracticed: Int?
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
        self.songId = songId
    }
}
