//
//  SongRepository.swift
//  beatclikr
//
//  Created by Ben Funk on 7/26/26.
//

import Foundation
import SwiftData

struct SongValues {
    let title: String
    let artist: String
    let beatsPerMinute: Double
    let beatsPerMeasure: Int
    let groove: Groove
    let beatPattern: String?

    init(
        title: String,
        artist: String,
        beatsPerMinute: Double,
        beatsPerMeasure: Int,
        groove: Groove,
        beatPattern: String?,
    ) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.artist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        self.beatsPerMinute = beatsPerMinute
        self.beatsPerMeasure = beatsPerMeasure
        self.groove = groove
        self.beatPattern = groove.isOddMeter ? beatPattern : nil
    }
}

@MainActor
protocol SongRepository {
    func save(
        _ song: Song,
        values: SongValues,
        context: ModelContext,
    ) -> Result<Song, PersistenceFailure>
    func delete(
        _ songs: [Song],
        context: ModelContext,
    ) -> Result<Void, PersistenceFailure>
}

@MainActor
struct SwiftDataSongRepository: SongRepository {
    private let persistence: any PersistenceRepository

    init(persistence: any PersistenceRepository = SwiftDataPersistenceRepository()) {
        self.persistence = persistence
    }

    func save(
        _ song: Song,
        values: SongValues,
        context: ModelContext,
    ) -> Result<Song, PersistenceFailure> {
        guard !values.title.isEmpty, !values.artist.isEmpty else {
            return .failure(.validation(message: String(localized: "Title and artist are required.")))
        }
        guard MetronomeConstants.minBPM ... MetronomeConstants.maxBPM ~= values.beatsPerMinute,
              values.beatsPerMeasure > 0
        else {
            return .failure(.validation(message: String(localized: "Enter a valid tempo and number of beats.")))
        }

        let wasPersisted = song.modelContext != nil
        let previous = (
            id: song.id,
            title: song.title,
            artist: song.artist,
            beatsPerMinute: song.beatsPerMinute,
            beatsPerMeasure: song.beatsPerMeasure,
            groove: song.groove,
            beatPattern: song.beatPattern,
        )

        song.id = song.id ?? UUID().uuidString
        song.title = values.title
        song.artist = values.artist
        song.beatsPerMinute = values.beatsPerMinute
        song.beatsPerMeasure = values.beatsPerMeasure
        song.groove = values.groove
        song.beatPattern = values.beatPattern
        if song.modelContext == nil {
            context.insert(song)
        }

        switch persistence.save(context) {
        case .success:
            return .success(song)
        case let .failure(failure):
            context.rollback()
            if wasPersisted {
                song.id = previous.id
                song.title = previous.title
                song.artist = previous.artist
                song.beatsPerMinute = previous.beatsPerMinute
                song.beatsPerMeasure = previous.beatsPerMeasure
                song.groove = previous.groove
                song.beatPattern = previous.beatPattern
            }
            return .failure(failure)
        }
    }

    func delete(
        _ songs: [Song],
        context: ModelContext,
    ) -> Result<Void, PersistenceFailure> {
        songs.forEach(context.delete)
        switch persistence.save(context) {
        case .success:
            return .success(())
        case let .failure(failure):
            context.rollback()
            return .failure(failure)
        }
    }
}
