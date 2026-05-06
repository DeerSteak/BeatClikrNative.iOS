//
//  Song.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import Foundation
import SwiftData

@Model
final class Song: Identifiable, SongDisplayable {
    var id: String?
    var title: String?
    var artist: String?
    var beatsPerMinute: Double?
    var beatsPerMeasure: Int?
    var groove: Groove?
    var beatPattern: String?

    @Relationship(deleteRule: .cascade)
    var playlistEntries: [PlaylistEntry]? = []

    @MainActor static let instantSong: Song = Song()

    init() {
        id = UUID().uuidString
        title = "Instant"
        artist = "Song"
        beatsPerMinute = 60
        beatsPerMeasure = 4
        groove = .quarter
    }

    init(title: String, artist: String, beatsPerMinute: Double, beatsPerMeasure: Int, groove: Groove) {
        id = UUID().uuidString
        self.title = title
        self.artist = artist
        self.beatsPerMinute = beatsPerMinute
        self.beatsPerMeasure = beatsPerMeasure
        self.groove = groove
    }
}
