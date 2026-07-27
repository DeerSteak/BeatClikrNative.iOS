//
//  PracticeSession.swift
//  beatclikr
//
//  Created by Ben Funk on 5/1/26.
//

import Foundation
import OSLog
import SwiftData

@Model
final class PracticeSession: Identifiable {
    var id: String?
    var date: Date?
    /// Gregorian local civil day captured when practice was recorded (`yyyy-MM-dd`).
    /// Unlike `date`, this identity does not change when the user changes time zone.
    var dayKey: String?
    var timeZoneIdentifier: String?
    var calendarIdentifier: String?

    @Relationship(deleteRule: .cascade)
    var songsPracticed: [PracticedSong]? = []

    init(
        date: Date,
        songsPracticed: [PracticedSong] = [],
        timeZone: TimeZone = .current,
    ) {
        let identity = PracticeDayIdentity(date: date, timeZone: timeZone)
        id = identity.sessionID
        self.date = date
        dayKey = identity.key
        timeZoneIdentifier = identity.timeZoneIdentifier
        calendarIdentifier = identity.calendarIdentifier
        self.songsPracticed = songsPracticed
    }
}

struct PracticeDayIdentity: Equatable {
    static let calendarIdentifier = "gregorian"

    let key: String
    let timeZoneIdentifier: String
    let calendarIdentifier: String

    var sessionID: String {
        "practice-day:\(key)"
    }

    init(date: Date, timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        key = String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
        )
        timeZoneIdentifier = timeZone.identifier
        calendarIdentifier = Self.calendarIdentifier
    }

    static func date(for key: String, timeZone: TimeZone = .current) -> Date? {
        let fields = key.split(separator: "-", omittingEmptySubsequences: false)
        guard fields.count == 3,
              let year = Int(fields[0]),
              let month = Int(fields[1]),
              let day = Int(fields[2])
        else {
            return nil
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}

@MainActor
enum PracticeDayRepair {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "BeatClikr",
        category: "PracticeDayRepair",
    )

    @discardableResult
    static func repairIfPossible(context: ModelContext) -> Bool {
        do {
            try repair(context: context)
            return true
        } catch {
            logger.error("Practice-day repair failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Migrates legacy sessions and merges CloudKit-created duplicates.
    ///
    /// The merge is idempotent: one canonical session remains for each day key,
    /// songs are grouped by stable song ID, and play counts are combined once.
    @discardableResult
    static func repair(
        context: ModelContext,
        timeZone: TimeZone = .current,
    ) throws -> Int {
        let sessions = try context.fetch(FetchDescriptor<PracticeSession>())
        var changed = 0

        for session in sessions {
            if session.dayKey == nil, let date = session.date {
                let identity = PracticeDayIdentity(date: date, timeZone: timeZone)
                session.dayKey = identity.key
                session.timeZoneIdentifier = identity.timeZoneIdentifier
                session.calendarIdentifier = identity.calendarIdentifier
                changed += 1
            }
            guard let dayKey = session.dayKey else { continue }
            if session.id != "practice-day:\(dayKey)" {
                session.id = "practice-day:\(dayKey)"
                changed += 1
            }
            if session.date == nil {
                session.date = PracticeDayIdentity.date(for: dayKey, timeZone: timeZone)
                changed += 1
            }
            if session.timeZoneIdentifier == nil {
                session.timeZoneIdentifier = timeZone.identifier
                changed += 1
            }
            if session.calendarIdentifier != PracticeDayIdentity.calendarIdentifier {
                session.calendarIdentifier = PracticeDayIdentity.calendarIdentifier
                changed += 1
            }
            if session.songsPracticed == nil {
                session.songsPracticed = []
                changed += 1
            }
            for song in session.songsPracticed ?? [] {
                if song.id == nil {
                    song.id = UUID().uuidString
                    changed += 1
                }
                if song.songId == nil {
                    song.songId = "legacy-practiced-song:\(song.id!)"
                    changed += 1
                }
                if song.title == nil {
                    song.title = String(localized: "Unknown")
                    changed += 1
                }
                if song.artist == nil {
                    song.artist = ""
                    changed += 1
                }
                if song.timesPracticed == nil || song.timesPracticed! < 1 {
                    song.timesPracticed = 1
                    changed += 1
                }
            }
        }

        let groups = Dictionary(grouping: sessions.compactMap { session in
            session.dayKey.map { ($0, session) }
        }, by: \.0)

        for (dayKey, keyedSessions) in groups {
            let duplicates = keyedSessions.map(\.1)
            guard duplicates.count > 1 else {
                if let only = duplicates.first, only.id != "practice-day:\(dayKey)" {
                    only.id = "practice-day:\(dayKey)"
                    changed += 1
                }
                continue
            }

            let canonical = duplicates.sorted {
                ($0.id ?? "") < ($1.id ?? "")
            }[0]
            let snapshots = mergedSongs(from: duplicates)
            let allSongs = duplicates.flatMap { $0.songsPracticed ?? [] }
            for session in duplicates {
                session.songsPracticed = []
            }
            allSongs.forEach { context.delete($0) }

            canonical.id = "practice-day:\(dayKey)"
            canonical.date = duplicates.compactMap(\.date).min()
            canonical.timeZoneIdentifier = duplicates.compactMap(\.timeZoneIdentifier).sorted().first
                ?? timeZone.identifier
            canonical.calendarIdentifier = PracticeDayIdentity.calendarIdentifier
            canonical.songsPracticed = snapshots.map { snapshot in
                let song = PracticedSong(snapshot: snapshot)
                context.insert(song)
                return song
            }

            for duplicate in duplicates where duplicate !== canonical {
                context.delete(duplicate)
            }
            changed += duplicates.count - 1
        }

        if changed > 0 {
            try context.save()
        }
        return changed
    }

    private static func mergedSongs(from sessions: [PracticeSession]) -> [PracticedSongSnapshot] {
        let songs = sessions
            .flatMap { $0.songsPracticed ?? [] }
            .sorted { ($0.id ?? "") < ($1.id ?? "") }
        let grouped = Dictionary(grouping: songs) { song in
            song.songId ?? "legacy-practiced-song:\(song.id ?? "")"
        }

        return grouped.keys.sorted().compactMap { key in
            guard let matches = grouped[key], let first = matches.first else { return nil }
            let isSingleCreditMode = key == Song.metronomeSongId || key == "beatclikr.polyrhythm"
            return PracticedSongSnapshot(
                id: matches.compactMap(\.id).sorted().first ?? UUID().uuidString,
                title: matches.compactMap(\.title).first,
                artist: matches.compactMap(\.artist).first,
                beatsPerMinute: matches.compactMap(\.beatsPerMinute).first,
                beatsPerMeasure: matches.compactMap(\.beatsPerMeasure).first,
                groove: matches.compactMap(\.groove).first,
                timesPracticed: isSingleCreditMode
                    ? min(1, matches.compactMap(\.timesPracticed).max() ?? 1)
                    : matches.reduce(0) { $0 + max(0, $1.timesPracticed ?? 0) },
                songId: first.songId,
            )
        }
    }
}
