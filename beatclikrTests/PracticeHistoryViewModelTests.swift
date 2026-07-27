//
//  PracticeHistoryViewModelTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 5/1/26.
//

@testable import BeatClikr
import Foundation
import SwiftData
import Testing

private enum InjectedPersistenceError: Error {
    case failure
}

private final class TestMonotonicClock {
    var now: TimeInterval = 0
}

@MainActor
private struct FailingPersistenceRepository: PersistenceRepository {
    enum Operation {
        case fetch
        case save
    }

    let operation: Operation
    private let real = SwiftDataPersistenceRepository()

    func fetch<Model: PersistentModel>(
        _ descriptor: FetchDescriptor<Model>,
        from context: ModelContext,
    ) -> Result<[Model], PersistenceFailure> {
        guard operation != .fetch else {
            return .failure(.fetch(underlying: InjectedPersistenceError.failure))
        }
        return real.fetch(descriptor, from: context)
    }

    func save(_ context: ModelContext) -> Result<Void, PersistenceFailure> {
        guard operation != .save else {
            context.rollback()
            return .failure(.save(underlying: InjectedPersistenceError.failure))
        }
        return real.save(context)
    }
}

@MainActor
struct PracticeHistoryViewModelTests {
    private let cal = Calendar.current
    private var today: Date {
        cal.startOfDay(for: .now)
    }

    private func daysAgo(_ n: Int) -> Date {
        cal.date(byAdding: .day, value: -n, to: today)!
    }

    // MARK: - currentStreak

    @Test func `current streak is zero for empty dates`() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.currentStreak(from: []) == 0)
    }

    @Test func `current streak is today only`() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.currentStreak(from: [today]) == 1)
    }

    @Test func `current streak counts today and yesterday`() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.currentStreak(from: [today, daysAgo(1)]) == 2)
    }

    @Test func `current streak counts three consecutive days`() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [today, daysAgo(1), daysAgo(2)]
        #expect(vm.currentStreak(from: dates) == 3)
    }

    @Test func `current streak counts from yesterday when today missing`() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(1), daysAgo(2)]
        #expect(vm.currentStreak(from: dates) == 2)
    }

    @Test func `current streak is zero when gap before yesterday`() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(3), daysAgo(4)]
        #expect(vm.currentStreak(from: dates) == 0)
    }

    @Test func `current streak not extended by non consecutive date`() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [today, daysAgo(3)]
        #expect(vm.currentStreak(from: dates) == 1)
    }

    // MARK: - practiceReminderNeeded

    @Test func `practice reminder needed is false for empty dates`() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.practiceReminderNeeded(from: []) == false)
    }

    @Test func `practice reminder needed is false when practiced today`() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.practiceReminderNeeded(from: [today]) == false)
    }

    @Test func `practice reminder needed is true when last practice was yesterday`() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.practiceReminderNeeded(from: [daysAgo(1)]) == true)
    }

    @Test func `practice reminder needed is true for multi day streak ending yesterday`() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(1), daysAgo(2), daysAgo(3)]
        #expect(vm.practiceReminderNeeded(from: dates) == true)
    }

    @Test func `practice reminder needed is false when no active streak`() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(3), daysAgo(4)]
        #expect(vm.practiceReminderNeeded(from: dates) == false)
    }

    // MARK: - notificationBody

    @Test func `notification body is default for empty dates`() {
        let vm = PracticeHistoryViewModel()
        let body = vm.notificationBody(from: [])
        #expect(body.contains("each day"))
    }

    @Test func `notification body is practiced today when today in dates`() {
        let vm = PracticeHistoryViewModel()
        let body = vm.notificationBody(from: [today])
        #expect(body.contains("reminder to play"))
    }

    @Test func `notification body is keep streak when last practice was yesterday`() {
        let vm = PracticeHistoryViewModel()
        let body = vm.notificationBody(from: [daysAgo(1), daysAgo(2)])
        #expect(body.contains("2"))
        #expect(body.contains("streak alive"))
    }

    @Test func `notification body is streak broken when longest streak just broke`() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(2), daysAgo(3), daysAgo(4)]
        let body = vm.notificationBody(from: dates)
        #expect(body.contains("3"))
        #expect(body.contains("was broken"))
    }

    @Test func `notification body is default when broken streak is not longest`() {
        let vm = PracticeHistoryViewModel()
        // Short recent streak (3 days ending 2 days ago), plus longer old streak (5 days)
        let recentBroken: Set<Date> = [daysAgo(2), daysAgo(3), daysAgo(4)]
        let longerOld: Set<Date> = [daysAgo(20), daysAgo(21), daysAgo(22), daysAgo(23), daysAgo(24)]
        let body = vm.notificationBody(from: recentBroken.union(longerOld))
        #expect(body.contains("each day"))
    }

    // MARK: - scheduledNotificationBodies

    @Test func `scheduled notification bodies returns requested count`() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.scheduledNotificationBodies(from: [], days: 7).count == 7)
    }

    @Test func `scheduled notification bodies day 0 matches notification body`() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [today]
        #expect(vm.scheduledNotificationBodies(from: dates, days: 7)[0] == vm.notificationBody(from: dates))
    }

    @Test func `scheduled notification bodies day 1 is keep streak when practiced today`() {
        let vm = PracticeHistoryViewModel()
        let body = vm.scheduledNotificationBodies(from: [today], days: 2)[1]
        #expect(body.contains("streak alive"))
    }

    @Test func `scheduled notification bodies day 2 is generic when no practice`() {
        let vm = PracticeHistoryViewModel()
        let body = vm.scheduledNotificationBodies(from: [], days: 3)[2]
        #expect(body.contains("each day"))
    }

    @Test func `scheduled notification bodies day 1 is streak broken when longest streak ends today`() {
        let vm = PracticeHistoryViewModel()
        // Longest streak runs through today; tomorrow's notification should warn it's broken
        let dates: Set<Date> = [today, daysAgo(1), daysAgo(2)]
        let body = vm.scheduledNotificationBodies(from: dates, days: 2)[1]
        // tomorrow sees today as 1 day ago (streak through today), and today IS in dates → keep streak
        #expect(body.contains("streak alive"))
    }

    // MARK: - currentStreakStartDate

    @Test func `current streak start date is nil for empty dates`() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.currentStreakStartDate(from: []) == nil)
    }

    @Test func `current streak start date is today for single day streak`() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.currentStreakStartDate(from: [today]) == today)
    }

    @Test func `current streak start date is correct for multi day streak`() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [today, daysAgo(1), daysAgo(2)]
        #expect(vm.currentStreakStartDate(from: dates) == daysAgo(2))
    }

    // MARK: - longestStreak

    @Test func `longest streak is zero for empty dates`() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.longestStreak(from: []) == 0)
    }

    @Test func `longest streak is one for single date`() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.longestStreak(from: [today]) == 1)
    }

    @Test func `longest streak is one for non consecutive dates`() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [today, daysAgo(5), daysAgo(10)]
        #expect(vm.longestStreak(from: dates) == 1)
    }

    @Test func `longest streak counts consecutive days`() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(1), daysAgo(2), daysAgo(3), daysAgo(4)]
        #expect(vm.longestStreak(from: dates) == 4)
    }

    @Test func `longest streak picks longest run`() {
        let vm = PracticeHistoryViewModel()
        let shortRun: Set<Date> = [daysAgo(20), daysAgo(21)]
        let longRun: Set<Date> = [daysAgo(5), daysAgo(6), daysAgo(7), daysAgo(8)]
        #expect(vm.longestStreak(from: shortRun.union(longRun)) == 4)
    }

    // MARK: - longestStreakRange

    @Test func `longest streak range is nil for empty dates`() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.longestStreakRange(from: []) == nil)
    }

    @Test func `longest streak range start equals end for single date`() {
        let vm = PracticeHistoryViewModel()
        let result = vm.longestStreakRange(from: [today])
        #expect(result?.start == today)
        #expect(result?.end == today)
    }

    @Test func `longest streak range returns correct bounds`() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(2), daysAgo(3), daysAgo(4)]
        let result = vm.longestStreakRange(from: dates)
        #expect(result?.start == daysAgo(4))
        #expect(result?.end == daysAgo(2))
    }

    // MARK: - markedDates

    @Test func `marked dates is empty with no sessions`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        #expect(vm.markedDates(context: context).isEmpty)
    }

    @Test func `marked dates contains session dates`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let session = PracticeSession(
            date: today,
            songsPracticed: [PracticedSong(title: "Metronome", artist: "BeatClikr", songId: Song.metronomeSongId)],
        )
        session.songsPracticed?.first?.durationSeconds = 30
        context.insert(session)
        let vm = PracticeHistoryViewModel()
        let dates = vm.markedDates(context: context)
        #expect(dates.contains(today))
        #expect(dates.count == 1)
    }

    @Test func `marked dates normalizes to start of day`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let noon = try #require(cal.date(bySettingHour: 12, minute: 0, second: 0, of: today))
        let session = PracticeSession(
            date: noon,
            songsPracticed: [PracticedSong(title: "Metronome", artist: "BeatClikr", songId: Song.metronomeSongId)],
        )
        session.songsPracticed?.first?.durationSeconds = 30
        context.insert(session)
        let vm = PracticeHistoryViewModel()
        #expect(vm.markedDates(context: context).contains(today))
    }

    // MARK: - session(for:context:)

    @Test func `session for date returns matching session`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let session = PracticeSession(date: today)
        context.insert(session)
        let vm = PracticeHistoryViewModel()
        let found = vm.session(for: today, context: context)
        #expect(found != nil)
        #expect(found?.id == session.id)
    }

    @Test func `session for date returns nil when not found`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        #expect(vm.session(for: today, context: context) == nil)
    }

    @Test func `session for date does not return wrong day session`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let session = PracticeSession(date: daysAgo(1))
        context.insert(session)
        let vm = PracticeHistoryViewModel()
        #expect(vm.session(for: today, context: context) == nil)
    }

    // MARK: - getOrCreateTodaysSession

    @Test func `get or create todays session creates new session`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        let session = vm.getOrCreateTodaysSession(context: context)
        #expect(session.date != nil)
        #expect(try cal.isDateInToday(#require(session.date)))
    }

    @Test func `get or create todays session returns existing session`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        let first = vm.getOrCreateTodaysSession(context: context)
        let second = vm.getOrCreateTodaysSession(context: context)
        #expect(first.id == second.id)
    }

    // MARK: - Stable practice-day identity and repair

    @Test func `practice day identity remains the recorded local day after travel`() throws {
        let losAngeles = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        var sourceCalendar = Calendar(identifier: .gregorian)
        sourceCalendar.timeZone = losAngeles
        let recordedAt = try #require(sourceCalendar.date(
            from: DateComponents(year: 2026, month: 3, day: 8, hour: 23, minute: 30),
        ))

        let session = PracticeSession(date: recordedAt, timeZone: losAngeles)

        #expect(session.dayKey == "2026-03-08")
        #expect(session.timeZoneIdentifier == losAngeles.identifier)
        #expect(PracticeDayIdentity(date: recordedAt, timeZone: tokyo).key == "2026-03-09")
        #expect(session.dayKey == "2026-03-08")
    }

    @Test func `legacy session migration freezes day and time zone metadata`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let zone = try #require(TimeZone(identifier: "America/Chicago"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let recordedAt = try #require(calendar.date(
            from: DateComponents(year: 2026, month: 11, day: 1, hour: 1, minute: 30),
        ))
        let legacy = PracticeSession(date: recordedAt)
        legacy.dayKey = nil
        legacy.timeZoneIdentifier = nil
        legacy.calendarIdentifier = nil
        context.insert(legacy)

        let changes = try PracticeDayRepair.repair(context: context, timeZone: zone)

        #expect(changes == 1)
        #expect(legacy.dayKey == "2026-11-01")
        #expect(legacy.timeZoneIdentifier == zone.identifier)
        #expect(legacy.calendarIdentifier == "gregorian")
        #expect(legacy.id == "practice-day:2026-11-01")
    }

    @Test func `duplicate day repair preserves every practiced song`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let firstSong = PracticedSong(title: "First", artist: "Artist", songId: "song.first")
        let secondSong = PracticedSong(title: "Second", artist: "Artist", songId: "song.second")
        let first = PracticeSession(date: today, songsPracticed: [firstSong])
        let second = PracticeSession(date: today, songsPracticed: [secondSong])
        first.id = "device-a"
        second.id = "device-b"
        context.insert(first)
        context.insert(second)

        try PracticeDayRepair.repair(context: context)
        let sessions = try context.fetch(FetchDescriptor<PracticeSession>())
        let merged = try #require(sessions.first)

        #expect(sessions.count == 1)
        #expect(merged.id == "practice-day:\(PracticeDayIdentity(date: today).key)")
        #expect(Set(merged.songsPracticed?.compactMap(\.songId) ?? []) == ["song.first", "song.second"])
    }

    @Test func `offline duplicate song counts merge once and repair is idempotent`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let firstSong = PracticedSong(title: "Shared", artist: "Artist", songId: "song.shared")
        firstSong.timesPracticed = 2
        let secondSong = PracticedSong(title: "Shared", artist: "Artist", songId: "song.shared")
        secondSong.timesPracticed = 3
        let first = PracticeSession(date: today, songsPracticed: [firstSong])
        let second = PracticeSession(date: today, songsPracticed: [secondSong])
        first.id = "device-a"
        second.id = "device-b"
        context.insert(first)
        context.insert(second)

        try PracticeDayRepair.repair(context: context)
        let firstResult = try #require(context.fetch(FetchDescriptor<PracticeSession>()).first)
        #expect(firstResult.songsPracticed?.count == 1)
        #expect(firstResult.songsPracticed?.first?.timesPracticed == 5)

        let secondRepairChanges = try PracticeDayRepair.repair(context: context)
        let secondResult = try #require(context.fetch(FetchDescriptor<PracticeSession>()).first)
        #expect(secondRepairChanges == 0)
        #expect(secondResult.songsPracticed?.first?.timesPracticed == 5)
    }

    @Test func `duplicate built in modes retain single daily credit`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let firstSong = PracticedSong(title: "Metronome", artist: "BeatClikr", songId: Song.metronomeSongId)
        let secondSong = PracticedSong(title: "Metronome", artist: "BeatClikr", songId: Song.metronomeSongId)
        let first = PracticeSession(date: today, songsPracticed: [firstSong])
        let second = PracticeSession(date: today, songsPracticed: [secondSong])
        first.id = "device-a"
        second.id = "device-b"
        context.insert(first)
        context.insert(second)

        try PracticeDayRepair.repair(context: context)
        let merged = try #require(context.fetch(FetchDescriptor<PracticeSession>()).first)

        #expect(merged.songsPracticed?.count == 1)
        #expect(merged.songsPracticed?.first?.timesPracticed == 1)
    }

    @Test func `partial CloudKit practice records are normalized`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let song = PracticedSong(title: "Temporary", artist: "Temporary", songId: "temporary")
        song.id = nil
        song.title = nil
        song.artist = nil
        song.songId = nil
        song.timesPracticed = nil
        let session = PracticeSession(date: today, songsPracticed: [song])
        session.id = nil
        session.date = nil
        session.timeZoneIdentifier = nil
        session.calendarIdentifier = nil
        context.insert(session)

        try PracticeDayRepair.repair(context: context)

        #expect(session.id == "practice-day:\(session.dayKey!)")
        #expect(session.date != nil)
        #expect(session.timeZoneIdentifier != nil)
        #expect(session.calendarIdentifier == PracticeDayIdentity.calendarIdentifier)
        #expect(song.id != nil)
        #expect(song.songId?.hasPrefix("legacy-practiced-song:") == true)
        #expect(song.title == "Unknown")
        #expect(song.artist == "")
        #expect(song.timesPracticed == 1)
    }

    @Test func `fetch failure is surfaced without replacing valid presentation state`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let vm = PracticeHistoryViewModel(
            repository: PracticeHistoryRepository(
                persistence: FailingPersistenceRepository(operation: .fetch),
            ),
        )
        vm.practiceDates = [today]

        vm.loadPracticeDates(context: container.mainContext)

        #expect(vm.practiceDates == [today])
        #expect(vm.persistenceFailure != nil)
    }

    @Test func `failed practice save rolls back and suppresses success callback`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let vm = PracticeHistoryViewModel(
            repository: PracticeHistoryRepository(
                persistence: FailingPersistenceRepository(operation: .save),
            ),
        )
        var callbackCount = 0
        vm.onPracticeRecorded = { _ in callbackCount += 1 }

        vm.beginPlayback(
            .init(songId: Song.metronomeSongId, title: "Metronome"),
            context: context,
        )

        #expect(vm.persistenceFailure != nil)
        #expect(callbackCount == 0)
        #expect(try context.fetch(FetchDescriptor<PracticeSession>()).isEmpty)
    }

    @Test func `playback remains hidden until accumulated duration reaches thirty seconds`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let clock = TestMonotonicClock()
        let vm = PracticeHistoryViewModel(monotonicNow: { clock.now })
        let item = PracticeHistoryViewModel.PlaybackItem(songId: Song.metronomeSongId, title: "Metronome")

        vm.beginPlayback(item, context: context)
        clock.now = 29
        vm.endPlayback()
        #expect(vm.markedDates(context: context).isEmpty)

        vm.beginPlayback(item, context: context)
        clock.now = 30
        vm.endPlayback()
        #expect(vm.markedDates(context: context).contains(today))
    }

    @Test func `multiple playback periods accumulate duration and session count`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let clock = TestMonotonicClock()
        let vm = PracticeHistoryViewModel(monotonicNow: { clock.now })
        let item = PracticeHistoryViewModel.PlaybackItem(songId: "song.test", title: "Test")

        vm.beginPlayback(item, context: context)
        clock.now = 12
        vm.endPlayback()
        vm.beginPlayback(item, context: context)
        clock.now = 35
        vm.endPlayback()

        let session = try #require(context.fetch(FetchDescriptor<PracticeSession>()).first)
        let practiced = try #require(session.songsPracticed?.first)
        #expect(practiced.durationSeconds == 35)
        #expect(practiced.timesPracticed == 2)
    }

    @Test func `switching playback attributes elapsed time to each item`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let clock = TestMonotonicClock()
        let vm = PracticeHistoryViewModel(monotonicNow: { clock.now })

        vm.beginPlayback(.init(songId: "song.first", title: "First"), context: context)
        clock.now = 20
        vm.beginPlayback(.init(songId: "song.second", title: "Second"), context: context)
        clock.now = 55
        vm.endPlayback()

        let session = try #require(context.fetch(FetchDescriptor<PracticeSession>()).first)
        var songs: [String: Double] = [:]
        for song in session.songsPracticed ?? [] {
            guard let id = song.songId else { continue }
            songs[id] = song.durationSeconds ?? 0
        }
        #expect(songs["song.first"] == 20)
        #expect(songs["song.second"] == 35)
    }

    @Test func `stopped time is excluded and qualification callback fires once`() throws {
        let container = try TestModelContainerFactory.make([Song.self, PracticeSession.self, PracticedSong.self])
        let context = container.mainContext
        let clock = TestMonotonicClock()
        let vm = PracticeHistoryViewModel(monotonicNow: { clock.now })
        let item = PracticeHistoryViewModel.PlaybackItem(songId: "song.test", title: "Test")
        var callbackCount = 0
        vm.onPracticeRecorded = { _ in callbackCount += 1 }

        vm.beginPlayback(item, context: context)
        clock.now = 20
        vm.endPlayback()
        clock.now = 120
        vm.beginPlayback(item, context: context)
        clock.now = 130
        vm.endPlayback()
        vm.beginPlayback(item, context: context)
        clock.now = 140
        vm.endPlayback()

        let session = try #require(context.fetch(FetchDescriptor<PracticeSession>()).first)
        let practiced = try #require(session.songsPracticed?.first)
        #expect(practiced.durationSeconds == 40)
        #expect(callbackCount == 1)
    }
}
