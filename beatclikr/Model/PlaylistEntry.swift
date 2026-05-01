//
//  PlaylistEntry.swift
//  beatclikr
//
//  Created by Ben Funk on 4/10/26.
//

import Foundation
import SwiftData

@Model
final class PlaylistEntry: Identifiable {
    var id: String?
    var sequence: Int?
    
    @Relationship(inverse: \Song.playlistEntries)
    var song: Song?
    
    @Relationship(inverse: \Playlist.entries)
    var playlist: Playlist?
    
    init(song: Song, sequence: Int) {
        self.id = UUID().uuidString
        self.song = song
        self.sequence = sequence
    }
}
