//
//  Item.swift
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
        self.id = UUID().uuidString
        self.title = "Instant"
        self.artist = "Song"
        self.beatsPerMinute = 60
        self.beatsPerMeasure = 4
        self.groove = .quarter
    }
    
    init(title: String, artist: String, beatsPerMinute: Double, beatsPerMeasure: Int, groove: Groove) {
        self.id = UUID().uuidString
        self.title = title
        self.artist = artist
        self.beatsPerMinute = beatsPerMinute
        self.beatsPerMeasure = beatsPerMeasure
        self.groove = groove
    }
}
