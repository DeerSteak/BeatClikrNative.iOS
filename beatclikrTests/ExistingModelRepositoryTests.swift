//
//  ExistingModelRepositoryTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 7/26/26.
//

@testable import BeatClikr
import SwiftData
import Testing

private enum RepositoryTestError: Error {
    case injectedFailure
}

@MainActor
private struct SaveFailingPersistence: PersistenceRepository {
    private let real = SwiftDataPersistenceRepository()

    func fetch<Model: PersistentModel>(
        _ descriptor: FetchDescriptor<Model>,
        from context: ModelContext,
    ) -> Result<[Model], PersistenceFailure> {
        real.fetch(descriptor, from: context)
    }

    func save(_: ModelContext) -> Result<Void, PersistenceFailure> {
        .failure(.save(underlying: RepositoryTestError.injectedFailure))
    }
}

@MainActor
struct ExistingModelRepositoryTests {
    private func makeContainer() throws -> ModelContainer {
        try TestModelContainerFactory.make([Song.self, Playlist.self, PlaylistEntry.self])
    }

    private func songValues(title: String = "New Title") -> SongValues {
        SongValues(
            title: title,
            artist: "Artist",
            beatsPerMinute: 120,
            beatsPerMeasure: 4,
            groove: .eighth,
            beatPattern: nil,
        )
    }

    @Test func `song create succeeds only after save`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repository = SwiftDataSongRepository()
        let song = Song(title: "", artist: "", beatsPerMinute: 60, beatsPerMeasure: 4, groove: .quarter)

        let result = repository.save(song, values: songValues(), context: context)

        #expect(result.isSuccess)
        #expect(try context.fetch(FetchDescriptor<Song>()).count == 1)
        #expect(song.title == "New Title")
    }

    @Test func `failed song create leaves no inserted record`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repository = SwiftDataSongRepository(persistence: SaveFailingPersistence())
        let song = Song(title: "", artist: "", beatsPerMinute: 60, beatsPerMeasure: 4, groove: .quarter)

        let result = repository.save(song, values: songValues(), context: context)

        #expect(result.isFailure)
        #expect(try context.fetch(FetchDescriptor<Song>()).isEmpty)
    }

    @Test func `failed song edit restores committed values`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let song = Song(title: "Original", artist: "Artist", beatsPerMinute: 90, beatsPerMeasure: 4, groove: .quarter)
        context.insert(song)
        try context.save()

        let repository = SwiftDataSongRepository(persistence: SaveFailingPersistence())
        let result = repository.save(song, values: songValues(title: "Changed"), context: context)

        #expect(result.isFailure)
        #expect(song.title == "Original")
        #expect(song.beatsPerMinute == 90)
    }

    @Test func `failed song delete restores record`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let song = Song(title: "Keep Me", artist: "Artist", beatsPerMinute: 90, beatsPerMeasure: 4, groove: .quarter)
        context.insert(song)
        try context.save()

        let repository = SwiftDataSongRepository(persistence: SaveFailingPersistence())
        let result = repository.delete([song], context: context)

        #expect(result.isFailure)
        #expect(try context.fetch(FetchDescriptor<Song>()).count == 1)
    }

    @Test func `failed playlist create leaves no inserted record`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repository = SwiftDataPlaylistRepository(persistence: SaveFailingPersistence())

        let result = repository.create(name: "Set", context: context)

        #expect(result.isFailure)
        #expect(try context.fetch(FetchDescriptor<Playlist>()).isEmpty)
    }

    @Test func `failed playlist rename and delete preserve committed record`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let playlist = Playlist(name: "Original")
        context.insert(playlist)
        try context.save()
        let repository = SwiftDataPlaylistRepository(persistence: SaveFailingPersistence())

        #expect(repository.rename(playlist, name: "Changed", context: context).isFailure)
        #expect(playlist.name == "Original")
        #expect(repository.delete([playlist], context: context).isFailure)
        #expect(try context.fetch(FetchDescriptor<Playlist>()).count == 1)
    }

    @Test func `playlist rejects duplicate songs`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let playlist = Playlist(name: "Set")
        let song = Song(title: "Song", artist: "Artist", beatsPerMinute: 120, beatsPerMeasure: 4, groove: .quarter)
        context.insert(playlist)
        context.insert(song)
        try context.save()
        let repository = SwiftDataPlaylistRepository()

        #expect(repository.add(song, to: playlist, context: context).isSuccess)
        #expect(repository.add(song, to: playlist, context: context).isFailure)
        #expect(try context.fetch(FetchDescriptor<PlaylistEntry>()).count == 1)
    }

    @Test func `failed playlist add leaves no entry`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let playlist = Playlist(name: "Set")
        let song = Song(title: "Song", artist: "Artist", beatsPerMinute: 120, beatsPerMeasure: 4, groove: .quarter)
        context.insert(playlist)
        context.insert(song)
        try context.save()
        let repository = SwiftDataPlaylistRepository(persistence: SaveFailingPersistence())

        #expect(repository.add(song, to: playlist, context: context).isFailure)
        #expect(try context.fetch(FetchDescriptor<PlaylistEntry>()).isEmpty)
    }

    @Test func `failed entry delete preserves entries and ordering`() throws {
        let (container, _, entries) = try populatedPlaylist()
        let context = container.mainContext
        let repository = SwiftDataPlaylistRepository(persistence: SaveFailingPersistence())

        #expect(repository.deleteEntries([entries[1]], from: entries, context: context).isFailure)
        let stored = try SwiftDataPlaylistRepository.orderedEntries(context.fetch(FetchDescriptor<PlaylistEntry>()))
        #expect(stored.count == 3)
        #expect(stored.map(\.sequence) == [0, 1, 2])
    }

    @Test func `failed reorder restores committed ordering`() throws {
        let (container, _, entries) = try populatedPlaylist()
        let context = container.mainContext
        let repository = SwiftDataPlaylistRepository(persistence: SaveFailingPersistence())

        #expect(repository.reorder(entries, fromOffsets: [0], toOffset: 3, context: context).isFailure)
        let stored = try SwiftDataPlaylistRepository.orderedEntries(context.fetch(FetchDescriptor<PlaylistEntry>()))
        #expect(stored.compactMap(\.song?.title) == ["One", "Two", "Three"])
        #expect(stored.map(\.sequence) == [0, 1, 2])
    }

    @Test func `partial entries sort deterministically after valid sequences`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let song = Song(title: "Song", artist: "Artist", beatsPerMinute: 120, beatsPerMeasure: 4, groove: .quarter)
        let first = PlaylistEntry(song: song, sequence: 0)
        let partialA = PlaylistEntry(song: song, sequence: 4)
        let partialB = PlaylistEntry(song: song, sequence: 4)
        partialA.id = nil
        partialB.id = nil
        partialA.sequence = nil
        partialB.sequence = nil
        context.insert(song)
        context.insert(first)
        context.insert(partialA)
        context.insert(partialB)
        try context.save()

        let firstOrdering = SwiftDataPlaylistRepository.orderedEntries([partialB, first, partialA])
        let secondOrdering = SwiftDataPlaylistRepository.orderedEntries([partialA, partialB, first])

        #expect(firstOrdering.map(\.persistentModelID) == secondOrdering.map(\.persistentModelID))
        #expect(firstOrdering.first?.persistentModelID == first.persistentModelID)
    }

    private func populatedPlaylist() throws -> (ModelContainer, Playlist, [PlaylistEntry]) {
        let container = try makeContainer()
        let context = container.mainContext
        let playlist = Playlist(name: "Set")
        let songs = ["One", "Two", "Three"].map {
            Song(title: $0, artist: "Artist", beatsPerMinute: 120, beatsPerMeasure: 4, groove: .quarter)
        }
        let entries = songs.enumerated().map { index, song in
            let entry = PlaylistEntry(song: song, sequence: index)
            entry.playlist = playlist
            return entry
        }
        context.insert(playlist)
        songs.forEach(context.insert)
        entries.forEach(context.insert)
        try context.save()
        return (container, playlist, entries)
    }
}

private extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var isFailure: Bool {
        !isSuccess
    }
}
