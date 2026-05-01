//
//  Playlist.swift
//  beatclikr
//
//  created by Ben Funk 4/30/26
//

import Foundation
import SwiftData

@Model
final class Playlist: Identifiable {
    var id: String?
    var name: String?
    var createdAt: Date = Date()
    
    @Relationship(deleteRule: .cascade)
    var entries: [PlaylistEntry]? = []
    
    init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        self.createdAt = Date()
    }
}
