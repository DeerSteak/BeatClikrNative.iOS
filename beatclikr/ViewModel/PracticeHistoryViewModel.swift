//
//  PracticeHistoryViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 5/1/26.
//

import Combine
import Foundation
import SwiftData

@MainActor
final class PracticeHistoryViewModel: ObservableObject {
    static let qualifyingDuration: TimeInterval = 30

    struct PlaybackItem {
        let songId: String
        let title: String
        let artist: String
        let beatsPerMinute: Double?
        let beatsPerMeasure: Int?
        let groove: Groove?

        init(song: Song) {
            songId = song.id ?? UUID().uuidString
            title = song.title ?? String(localized: "Unknown")
            artist = song.artist ?? ""
            beatsPerMinute = song.beatsPerMinute
            beatsPerMeasure = song.beatsPerMeasure
            groove = song.groove
        }

        init(songId: String, title: String, artist: String = "BeatClikr") {
            self.songId = songId
            self.title = title
            self.artist = artist
            beatsPerMinute = nil
            beatsPerMeasure = nil
            groove = nil
        }
    }

    private struct ActivePlayback {
        let item: PlaybackItem
        let context: ModelContext
        var checkpoint: TimeInterval
    }

    var onPracticeRecorded: ((ModelContext) -> Void)?

    @Published var practiceDates: Set<Date> = []
    @Published var selectedDateSongs: [PracticedSong] = []
    @Published var persistenceFailure: PersistenceFailure?
    private let repository: PracticeHistoryRepository
    private let monotonicNow: () -> TimeInterval
    private var activePlayback: ActivePlayback?
    private var checkpointTask: Task<Void, Never>?

    init(
        repository: PracticeHistoryRepository = PracticeHistoryRepository(),
        monotonicNow: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
    ) {
        self.repository = repository
        self.monotonicNow = monotonicNow
    }

    var currentStreak: Int {
        currentStreak(from: practiceDates)
    }

    var longestStreak: Int {
        longestStreak(from: practiceDates)
    }

    var reminderNeeded: Bool {
        practiceReminderNeeded(from: practiceDates)
    }

    var currentStreakSubtitle: String {
        guard let start = currentStreakStartDate(from: practiceDates) else { return String(localized: "Let's go!") }
        return String(format: String(localized: "Since %@"), start.formatted(.dateTime.month().day().year()))
    }

    var longestStreakSubtitle: String {
        guard let range = longestStreakRange(from: practiceDates) else { return String(localized: "Let's go!") }
        let fmt = Date.FormatStyle().month(.defaultDigits).day(.defaultDigits).year(.twoDigits)
        if Calendar.current.isDate(range.start, inSameDayAs: range.end) {
            return range.start.formatted(fmt)
        }
        return "\(range.start.formatted(fmt)) – \(range.end.formatted(fmt))"
    }

    var shareText: String {
        let link = "https://apps.apple.com/app/id1512245974"
        if currentStreak > 0 {
            return "I'm on a \(currentStreak)-day streak with BeatClikr! 🎵 \nDownload it now: \(link)"
        } else if longestStreak > 0 {
            return "My longest BeatClikr practice streak is \(longestStreak) days! Try to break my record. 🎶 \nDownload it now: \(link)"
        } else {
            return "I've been practicing with BeatClikr! 🎼 \nDownload it now: \(link)"
        }
    }

    func loadPracticeDates(context: ModelContext) {
        persistenceFailure = nil
        let dates = markedDates(context: context)
        guard persistenceFailure == nil else { return }
        practiceDates = dates
    }

    func loadSongs(for date: Date?, context: ModelContext) {
        guard let date else { selectedDateSongs = []; return }
        persistenceFailure = nil
        let songs = (session(for: date, context: context)?.songsPracticed ?? [])
            .filter { ($0.durationSeconds ?? Self.qualifyingDuration) >= Self.qualifyingDuration }
        guard persistenceFailure == nil else { return }
        selectedDateSongs = sortedPracticeSongs(songs)
    }

    func getOrCreateTodaysSession(context: ModelContext) -> PracticeSession {
        PracticeDayRepair.repairIfPossible(context: context)
        let key = PracticeDayIdentity(date: .now).key
        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { $0.dayKey == key },
        )

        if case let .success(sessions) = repository.sessions(matching: descriptor, context: context),
           let existing = sessions.first
        {
            return existing
        }

        let session = PracticeSession(date: .now)
        context.insert(session)
        return session
    }

    func session(for date: Date, context: ModelContext) -> PracticeSession? {
        PracticeDayRepair.repairIfPossible(context: context)
        let key = PracticeDayIdentity(date: date).key
        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { $0.dayKey == key },
        )
        switch repository.sessions(matching: descriptor, context: context) {
        case let .success(sessions):
            return sessions.first
        case let .failure(error):
            persistenceFailure = error
            return nil
        }
    }

    func markedDates(context: ModelContext) -> Set<Date> {
        PracticeDayRepair.repairIfPossible(context: context)
        let descriptor = FetchDescriptor<PracticeSession>()
        let sessions: [PracticeSession]
        switch repository.sessions(matching: descriptor, context: context) {
        case let .success(fetched):
            sessions = fetched
        case let .failure(error):
            persistenceFailure = error
            return []
        }
        return Set(sessions.compactMap { session in
            guard (session.songsPracticed ?? []).contains(where: {
                ($0.durationSeconds ?? Self.qualifyingDuration) >= Self.qualifyingDuration
            }) else { return nil }
            return session.dayKey.flatMap { PracticeDayIdentity.date(for: $0) }
        })
    }

    func beginPlayback(_ item: PlaybackItem, context: ModelContext) {
        if activePlayback?.item.songId == item.songId { return }
        endPlayback()
        activePlayback = ActivePlayback(item: item, context: context, checkpoint: monotonicNow())
        incrementPlaybackPeriod(item, context: context)
        checkpointTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return }
                self?.checkpointPlayback()
            }
        }
    }

    func endPlayback() {
        checkpointPlayback()
        checkpointTask?.cancel()
        checkpointTask = nil
        activePlayback = nil
    }

    func checkpointPlayback() {
        guard var activePlayback else { return }
        let now = monotonicNow()
        let elapsed = max(0, now - activePlayback.checkpoint)
        guard elapsed > 0 else { return }
        activePlayback.checkpoint = now
        self.activePlayback = activePlayback
        let practiced = practicedSong(for: activePlayback.item, context: activePlayback.context)
        let wasQualified = (practiced.durationSeconds ?? 0) >= Self.qualifyingDuration
        practiced.durationSeconds = (practiced.durationSeconds ?? 0) + elapsed
        let isQualified = (practiced.durationSeconds ?? 0) >= Self.qualifyingDuration
        commitPractice(context: activePlayback.context, notifyPracticeRecorded: !wasQualified && isQualified)
    }

    func currentStreak(from dates: Set<Date>) -> Int {
        currentStreakInfo(from: dates).length
    }

    func currentStreakStartDate(from dates: Set<Date>) -> Date? {
        currentStreakInfo(from: dates).start
    }

    func longestStreak(from dates: Set<Date>) -> Int {
        longestStreakInfo(from: dates)?.length ?? 0
    }

    func longestStreakRange(from dates: Set<Date>) -> (start: Date, end: Date)? {
        longestStreakInfo(from: dates).map { ($0.start, $0.end) }
    }

    func practiceReminderNeeded(from dates: Set<Date>) -> Bool {
        let today = Calendar.current.startOfDay(for: .now)
        return currentStreak(from: dates) > 0 && !dates.contains(today)
    }

    func notificationBody(from dates: Set<Date>) -> String {
        projectedBody(from: dates, referenceDate: .now)
    }

    func notificationBody(from dates: Set<Date>, for date: Date) -> String {
        projectedBody(from: dates, referenceDate: date)
    }

    func scheduledNotificationBodies(from dates: Set<Date>, days: Int) -> [String] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0 ..< days).map { d in
            projectedBody(from: dates, referenceDate: cal.date(byAdding: .day, value: d, to: today)!)
        }
    }

    func sortedPracticeSongs(_ songs: [PracticedSong]) -> [PracticedSong] {
        songs.sorted { lhs, rhs in
            let lhsKey = practiceSortKey(lhs)
            let rhsKey = practiceSortKey(rhs)
            if lhsKey.rank != rhsKey.rank { return lhsKey.rank < rhsKey.rank }
            let titleOrder = lhsKey.title.localizedCaseInsensitiveCompare(rhsKey.title)
            if titleOrder != .orderedSame { return titleOrder == .orderedAscending }
            let artistOrder = lhsKey.artist.localizedCaseInsensitiveCompare(rhsKey.artist)
            if artistOrder != .orderedSame { return artistOrder == .orderedAscending }
            if lhsKey.songID != rhsKey.songID { return lhsKey.songID < rhsKey.songID }
            return lhsKey.recordID < rhsKey.recordID
        }
    }

    private func projectedBody(from dates: Set<Date>, referenceDate: Date) -> String {
        let cal = Calendar.current
        let refDay = cal.startOfDay(for: referenceDate)
        let yesterday = cal.date(byAdding: .day, value: -1, to: refDay)!
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: refDay)!

        if dates.contains(refDay) {
            return String(localized: "PracticeReminderNotificationBodyPracticedToday")
        }

        if dates.contains(yesterday) {
            var check = yesterday
            var streak = 0
            while dates.contains(check) {
                streak += 1
                check = cal.date(byAdding: .day, value: -1, to: check)!
            }
            return String(format: String(localized: "PracticeReminderNotificationBodyKeepStreak"), Int64(streak))
        }

        if dates.contains(twoDaysAgo) {
            var check = twoDaysAgo
            var brokenLen = 0
            while dates.contains(check) {
                brokenLen += 1
                check = cal.date(byAdding: .day, value: -1, to: check)!
            }
            if brokenLen == longestStreak(from: dates) {
                return String(format: String(localized: "PracticeReminderNotificationBodyStreakBroken"), Int64(brokenLen))
            }
        }

        return String(localized: "PracticeReminderNotificationBody")
    }

    // MARK: - Private helpers

    private func practiceSortKey(_ song: PracticedSong) -> (
        rank: Int,
        title: String,
        artist: String,
        songID: String,
        recordID: String,
    ) {
        let rank = switch song.songId {
        case Song.metronomeSongId: 0
        case "beatclikr.polyrhythm": 1
        default: 2
        }
        return (
            rank,
            song.title ?? "",
            song.artist ?? "",
            song.songId ?? "",
            song.id ?? "",
        )
    }

    private func incrementPlaybackPeriod(_ item: PlaybackItem, context: ModelContext) {
        let practiced = practicedSong(for: item, context: context)
        practiced.timesPracticed = (practiced.timesPracticed ?? 0) + 1
        commitPractice(context: context, notifyPracticeRecorded: false)
    }

    private func practicedSong(for item: PlaybackItem, context: ModelContext) -> PracticedSong {
        let session = getOrCreateTodaysSession(context: context)
        if let existing = session.songsPracticed?.first(where: { $0.songId == item.songId }) {
            return existing
        }
        let practiced = PracticedSong(title: item.title, artist: item.artist, songId: item.songId)
        practiced.beatsPerMinute = item.beatsPerMinute
        practiced.beatsPerMeasure = item.beatsPerMeasure
        practiced.groove = item.groove
        practiced.timesPracticed = 0
        practiced.durationSeconds = 0
        session.songsPracticed?.append(practiced)
        return practiced
    }

    private func commitPractice(context: ModelContext, notifyPracticeRecorded: Bool) {
        switch repository.commit(context: context) {
        case .success:
            persistenceFailure = nil
            loadPracticeDates(context: context)
            if notifyPracticeRecorded {
                onPracticeRecorded?(context)
            }
        case let .failure(error):
            persistenceFailure = error
            checkpointTask?.cancel()
            checkpointTask = nil
            activePlayback = nil
        }
    }

    private func currentStreakInfo(from dates: Set<Date>) -> (length: Int, start: Date?) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var check = dates.contains(today) ? today : cal.date(byAdding: .day, value: -1, to: today)!
        guard dates.contains(check) else { return (0, nil) }
        var streak = 0
        while dates.contains(check) {
            streak += 1
            check = cal.date(byAdding: .day, value: -1, to: check)!
        }
        let start = cal.date(byAdding: .day, value: 1, to: check)
        return (streak, start)
    }

    private func longestStreakInfo(from dates: Set<Date>) -> (length: Int, start: Date, end: Date)? {
        guard !dates.isEmpty else { return nil }
        let cal = Calendar.current
        let sorted = dates.sorted()
        var bestStart = sorted[0], bestEnd = sorted[0], bestLen = 1
        var curStart = sorted[0], curLen = 1
        for i in 1 ..< sorted.count {
            if let next = cal.date(byAdding: .day, value: 1, to: sorted[i - 1]),
               cal.isDate(next, inSameDayAs: sorted[i])
            {
                curLen += 1
                if curLen > bestLen {
                    bestLen = curLen
                    bestStart = curStart
                    bestEnd = sorted[i]
                }
            } else {
                curStart = sorted[i]
                curLen = 1
            }
        }
        return (bestLen, bestStart, bestEnd)
    }
}
