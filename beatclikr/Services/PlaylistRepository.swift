//
//  PlaylistRepository.swift
//  beatclikr
//
//  Created by Ben Funk on 7/26/26.
//

import Foundation
import SwiftData

@MainActor
protocol PlaylistRepository {
    func create(name: String, context: ModelContext) -> Result<Playlist, PersistenceFailure>
    func rename(_ playlist: Playlist, name: String, context: ModelContext) -> Result<Void, PersistenceFailure>
    func delete(_ playlists: [Playlist], context: ModelContext) -> Result<Void, PersistenceFailure>
    func add(_ song: Song, to playlist: Playlist, context: ModelContext) -> Result<PlaylistEntry, PersistenceFailure>
    func deleteEntries(
        _ entriesToDelete: [PlaylistEntry],
        from orderedEntries: [PlaylistEntry],
        context: ModelContext,
    ) -> Result<Void, PersistenceFailure>
    func reorder(
        _ orderedEntries: [PlaylistEntry],
        fromOffsets: IndexSet,
        toOffset: Int,
        context: ModelContext,
    ) -> Result<Void, PersistenceFailure>
}

@MainActor
struct SwiftDataPlaylistRepository: PlaylistRepository {
    private let persistence: any PersistenceRepository

    init(persistence: any PersistenceRepository = SwiftDataPersistenceRepository()) {
        self.persistence = persistence
    }

    static func orderedEntries(_ entries: [PlaylistEntry]) -> [PlaylistEntry] {
        entries.sorted {
            let lhsSequence = $0.sequence ?? .max
            let rhsSequence = $1.sequence ?? .max
            if lhsSequence != rhsSequence { return lhsSequence < rhsSequence }
            return stableIdentity(for: $0) < stableIdentity(for: $1)
        }
    }

    func create(name: String, context: ModelContext) -> Result<Playlist, PersistenceFailure> {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(.validation(message: String(localized: "Playlist name is required.")))
        }
        let playlist = Playlist(name: trimmed)
        context.insert(playlist)
        return commit(context).map { playlist }
    }

    func rename(_ playlist: Playlist, name: String, context: ModelContext) -> Result<Void, PersistenceFailure> {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(.validation(message: String(localized: "Playlist name is required.")))
        }
        let previousID = playlist.id
        let previousName = playlist.name
        playlist.id = playlist.id ?? UUID().uuidString
        playlist.name = trimmed
        return commit(context) {
            playlist.id = previousID
            playlist.name = previousName
        }
    }

    func delete(_ playlists: [Playlist], context: ModelContext) -> Result<Void, PersistenceFailure> {
        playlists.forEach(context.delete)
        return commit(context)
    }

    func add(_ song: Song, to playlist: Playlist, context: ModelContext) -> Result<PlaylistEntry, PersistenceFailure> {
        let entries = Self.orderedEntries(playlist.entries ?? [])
        guard !entries.contains(where: { entry in
            guard let existing = entry.song else { return false }
            return existing.persistentModelID == song.persistentModelID
                || (existing.id != nil && existing.id == song.id)
        }) else {
            return .failure(.conflict(message: String(localized: "That song is already in this playlist.")))
        }

        let previousPlaylistID = playlist.id
        let previousSongID = song.id
        playlist.id = playlist.id ?? UUID().uuidString
        song.id = song.id ?? UUID().uuidString
        let entry = PlaylistEntry(song: song, sequence: entries.count)
        entry.playlist = playlist
        context.insert(entry)
        return commit(context) {
            playlist.id = previousPlaylistID
            song.id = previousSongID
        }.map { entry }
    }

    func deleteEntries(
        _ entriesToDelete: [PlaylistEntry],
        from orderedEntries: [PlaylistEntry],
        context: ModelContext,
    ) -> Result<Void, PersistenceFailure> {
        let deleting = Set(entriesToDelete.map(\.persistentModelID))
        let previousOrdering = orderedEntries.map { ($0, $0.id, $0.sequence) }
        entriesToDelete.forEach(context.delete)
        let remaining = orderedEntries.filter { !deleting.contains($0.persistentModelID) }
        assignSequences(remaining)
        return commit(context) {
            for (entry, id, sequence) in previousOrdering {
                entry.id = id
                entry.sequence = sequence
            }
        }
    }

    func reorder(
        _ orderedEntries: [PlaylistEntry],
        fromOffsets: IndexSet,
        toOffset: Int,
        context: ModelContext,
    ) -> Result<Void, PersistenceFailure> {
        guard fromOffsets.allSatisfy(orderedEntries.indices.contains),
              toOffset >= 0,
              toOffset <= orderedEntries.count
        else {
            return .failure(.validation(message: String(localized: "The playlist order could not be applied.")))
        }
        let previousOrdering = orderedEntries.map { ($0, $0.id, $0.sequence) }
        var revised = orderedEntries
        revised.move(fromOffsets: fromOffsets, toOffset: toOffset)
        assignSequences(revised)
        return commit(context) {
            for (entry, id, sequence) in previousOrdering {
                entry.id = id
                entry.sequence = sequence
            }
        }
    }

    private func commit(
        _ context: ModelContext,
        restore: () -> Void = {},
    ) -> Result<Void, PersistenceFailure> {
        switch persistence.save(context) {
        case .success:
            return .success(())
        case let .failure(failure):
            context.rollback()
            restore()
            return .failure(failure)
        }
    }

    private func assignSequences(_ entries: [PlaylistEntry]) {
        for (index, entry) in entries.enumerated() {
            entry.id = entry.id ?? UUID().uuidString
            entry.sequence = index
        }
    }

    private static func stableIdentity(for entry: PlaylistEntry) -> String {
        entry.id ?? String(describing: entry.persistentModelID)
    }
}
