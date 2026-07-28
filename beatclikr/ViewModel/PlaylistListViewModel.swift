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
final class PlaylistListViewModel: ObservableObject {
    @Published private(set) var persistenceFailure: PersistenceFailure?

    private let repository: any PlaylistRepository

    init(repository: any PlaylistRepository = SwiftDataPlaylistRepository()) {
        self.repository = repository
    }

    @discardableResult
    func createPlaylist(name: String, context: ModelContext) -> Playlist? {
        switch repository.create(name: name, context: context) {
        case let .success(playlist):
            persistenceFailure = nil
            return playlist
        case let .failure(failure):
            persistenceFailure = failure
            return nil
        }
    }

    @discardableResult
    func renamePlaylist(_ playlist: Playlist, name: String, context: ModelContext) -> Bool {
        switch repository.rename(playlist, name: name, context: context) {
        case .success:
            persistenceFailure = nil
            return true
        case let .failure(failure):
            persistenceFailure = failure
            return false
        }
    }

    @discardableResult
    func deletePlaylists(offsets: IndexSet, playlists: [Playlist], context: ModelContext) -> Bool {
        let selected = offsets.compactMap { playlists.indices.contains($0) ? playlists[$0] : nil }
        switch repository.delete(selected, context: context) {
        case .success:
            persistenceFailure = nil
            return true
        case let .failure(failure):
            persistenceFailure = failure
            return false
        }
    }

    func dismissPersistenceFailure() {
        persistenceFailure = nil
    }
}
