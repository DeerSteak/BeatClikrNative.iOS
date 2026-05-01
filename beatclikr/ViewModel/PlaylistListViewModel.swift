//
//  PlaylistListViewModel.swift
//  beatclikr
//
//  created by Ben Funk 4/30/26
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class PlaylistListViewModel: ObservableObject {
    
    @discardableResult
    func createPlaylist(name: String, context: ModelContext) -> Playlist {
        let playlist = Playlist(name: name)
        context.insert(playlist)
        do {
            try context.save()
        } catch {
            print("Failed to create playlist: \(error)")
        }
        return playlist
    }
    
    func deletePlaylists(offsets: IndexSet, playlists: [Playlist], context: ModelContext) {
        withAnimation {
            for index in offsets {
                context.delete(playlists[index])
            }
            do {
                try context.save()
            } catch {
                print("Failed to delete playlists: \(error)")
            }
        }
    }
}
