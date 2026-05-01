//
//  PracticedSong.swift
//  beatclikr
//
//  Created by Ben Funk on 5/1/26.
//

import Foundation
import SwiftData

@Model
final class PracticedSong: Identifiable {
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
        self.id = UUID().uuidString
        self.title = song.title
        self.artist = song.artist
        self.beatsPerMinute = song.beatsPerMinute
        self.beatsPerMeasure = song.beatsPerMeasure
        self.groove = song.groove
        self.timesPracticed = 1
        self.songId = song.id
    }
}
