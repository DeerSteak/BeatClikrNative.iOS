//
//  Item.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import Foundation
import SwiftData

@Model
final class Song : Identifiable {
    var id: String
    var title: String
    var artist: String
    var beatsPerMinute: Int
    var beatsPerMeasure: Int
    var liveSequence: Int?
    var rehearsalSequence: Int?
        
    init(title: String, artist: String, beatsPerMinute: Int, beatsPerMeasure: Int) {
        self.id = UUID().uuidString
        self.title = title
        self.artist = artist
        self.beatsPerMinute = beatsPerMinute
        self.beatsPerMeasure = beatsPerMeasure
    }
}
