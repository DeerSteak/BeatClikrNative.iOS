//
//  PlaylistDetailViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 4/11/26.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class PlaylistDetailViewModel: SongNavigationViewModel {
    @Published private(set) var persistenceFailure: PersistenceFailure?

    private let repository: any PlaylistRepository

    init(repository: any PlaylistRepository = SwiftDataPlaylistRepository()) {
        self.repository = repository
        super.init()
    }

    static func orderedEntries(_ entries: [PlaylistEntry]) -> [PlaylistEntry] {
        SwiftDataPlaylistRepository.orderedEntries(entries)
    }

    @discardableResult
    func addSongToPlaylist(_ song: Song, playlist: Playlist, context: ModelContext) -> Bool {
        switch repository.add(song, to: playlist, context: context) {
        case .success:
            persistenceFailure = nil
            return true
        case let .failure(failure):
            persistenceFailure = failure
            return false
        }
    }

    @discardableResult
    func deleteEntries(offsets: IndexSet, entries: [PlaylistEntry], context: ModelContext) -> Bool {
        let selected = offsets.compactMap { entries.indices.contains($0) ? entries[$0] : nil }
        switch repository.deleteEntries(selected, from: entries, context: context) {
        case .success:
            persistenceFailure = nil
            return true
        case let .failure(failure):
            persistenceFailure = failure
            return false
        }
    }

    @discardableResult
    func sortEntries(fromOffsets: IndexSet, toOffset: Int, entries: [PlaylistEntry], context: ModelContext) -> Bool {
        switch repository.reorder(entries, fromOffsets: fromOffsets, toOffset: toOffset, context: context) {
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
