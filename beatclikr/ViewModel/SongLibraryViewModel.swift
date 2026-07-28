//
//  SongLibraryViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class SongLibraryViewModel: SongNavigationViewModel {
    @Published private(set) var persistenceFailure: PersistenceFailure?

    private let repository: any SongRepository

    init(repository: any SongRepository = SwiftDataSongRepository()) {
        self.repository = repository
        super.init()
    }

    @discardableResult
    func saveSong(_ song: Song, values: SongValues, context: ModelContext) -> Bool {
        switch repository.save(song, values: values, context: context) {
        case .success:
            persistenceFailure = nil
            return true
        case let .failure(failure):
            persistenceFailure = failure
            return false
        }
    }

    @discardableResult
    func deleteItems(offsets: IndexSet, items: [Song], context: ModelContext) -> Bool {
        let songs = offsets.compactMap { items.indices.contains($0) ? items[$0] : nil }
        switch repository.delete(songs, context: context) {
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
