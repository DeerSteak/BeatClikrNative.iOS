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
        id = UUID().uuidString
        self.name = name
        createdAt = Date()
    }

    var displayName: String {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.flatMap { $0.isEmpty ? nil : $0 } ?? String(localized: "Playlist")
    }
}
