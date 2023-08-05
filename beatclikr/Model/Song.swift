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
    var beatsPerMinute: Double
    var beatsPerMeasure: Int
    var liveSequence: Int?
    var rehearsalSequence: Int?
    
    init() {
        self.id = UUID().uuidString
        self.title = ""
        self.artist = ""
        self.beatsPerMinute = 60
        self.beatsPerMeasure = 4
    }
        
    init(title: String, artist: String, beatsPerMinute: Double, beatsPerMeasure: Int) {
        self.id = UUID().uuidString
        self.title = title
        self.artist = artist
        self.beatsPerMinute = beatsPerMinute
        self.beatsPerMeasure = beatsPerMeasure
    }
}
