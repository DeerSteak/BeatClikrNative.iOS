//
//  PracticeSession.swift
//  beatclikr
//
//  Created by Ben Funk on 5/1/26.
//

import Foundation
import SwiftData

@Model
final class PracticeSession: Identifiable {
    var id: String?
    var date: Date?
    
    @Relationship(deleteRule: .cascade)
    var songsPracticed: [PracticedSong]? = []
    
    init(date: Date, songsPracticed: [PracticedSong] = []) {
        self.id = UUID().uuidString
        self.date = date
        self.songsPracticed = songsPracticed
    }
}
