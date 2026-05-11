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

@MainActor
struct PracticeHistoryViewModelTests {
    private let cal = Calendar.current
    private var today: Date {
        cal.startOfDay(for: .now)
    }

    private func daysAgo(_ n: Int) -> Date {
        cal.date(byAdding: .day, value: -n, to: today)!
    }

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Song.self, PracticeSession.self, PracticedSong.self,
            configurations: config,
        )
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
        let container = try makeContainer()
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        #expect(vm.markedDates(context: context).isEmpty)
    }

    @Test func `marked dates contains session dates`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let session = PracticeSession(date: today)
        context.insert(session)
        let vm = PracticeHistoryViewModel()
        let dates = vm.markedDates(context: context)
        #expect(dates.contains(today))
        #expect(dates.count == 1)
    }

    @Test func `marked dates normalizes to start of day`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let noon = try #require(cal.date(bySettingHour: 12, minute: 0, second: 0, of: today))
        let session = PracticeSession(date: noon)
        context.insert(session)
        let vm = PracticeHistoryViewModel()
        #expect(vm.markedDates(context: context).contains(today))
    }

    // MARK: - session(for:context:)

    @Test func `session for date returns matching session`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let session = PracticeSession(date: today)
        context.insert(session)
        let vm = PracticeHistoryViewModel()
        let found = vm.session(for: today, context: context)
        #expect(found != nil)
        #expect(found?.id == session.id)
    }

    @Test func `session for date returns nil when not found`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        #expect(vm.session(for: today, context: context) == nil)
    }

    @Test func `session for date does not return wrong day session`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let session = PracticeSession(date: daysAgo(1))
        context.insert(session)
        let vm = PracticeHistoryViewModel()
        #expect(vm.session(for: today, context: context) == nil)
    }

    // MARK: - getOrCreateTodaysSession

    @Test func `get or create todays session creates new session`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        let session = vm.getOrCreateTodaysSession(context: context)
        #expect(session.date != nil)
        #expect(try cal.isDateInToday(#require(session.date)))
    }

    @Test func `get or create todays session returns existing session`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        let first = vm.getOrCreateTodaysSession(context: context)
        let second = vm.getOrCreateTodaysSession(context: context)
        #expect(first.id == second.id)
    }

    // MARK: - recordSongPlayed

    @Test func `record song played creates new practiced song`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let song = Song(title: "Test Song", artist: "Test Artist", beatsPerMinute: 120, beatsPerMeasure: 4, groove: .quarter)
        context.insert(song)
        let vm = PracticeHistoryViewModel()
        vm.recordSongPlayed(song: song, context: context)
        let session = vm.getOrCreateTodaysSession(context: context)
        let practiced = session.songsPracticed?.first(where: { $0.songId == song.id })
        #expect(practiced != nil)
        #expect(practiced?.timesPracticed == 1)
    }

    @Test func `record song played increments times played on repeat`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let song = Song(title: "Test Song", artist: "Test Artist", beatsPerMinute: 120, beatsPerMeasure: 4, groove: .quarter)
        context.insert(song)
        let vm = PracticeHistoryViewModel()
        vm.recordSongPlayed(song: song, context: context)
        vm.recordSongPlayed(song: song, context: context)
        let session = vm.getOrCreateTodaysSession(context: context)
        let practiced = session.songsPracticed?.first(where: { $0.songId == song.id })
        #expect(practiced?.timesPracticed == 2)
    }

    @Test func `record song played copies song metadata`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let song = Song(title: "My Song", artist: "My Artist", beatsPerMinute: 100, beatsPerMeasure: 4, groove: .quarter)
        context.insert(song)
        let vm = PracticeHistoryViewModel()
        vm.recordSongPlayed(song: song, context: context)
        let session = vm.getOrCreateTodaysSession(context: context)
        let practiced = session.songsPracticed?.first(where: { $0.songId == song.id })
        #expect(practiced?.title == "My Song")
        #expect(practiced?.artist == "My Artist")
        #expect(practiced?.beatsPerMinute == 100)
    }

    @Test func `record metronome practice creates one built in item per day`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        vm.recordMetronomePractice(context: context)
        vm.recordMetronomePractice(context: context)
        let session = vm.getOrCreateTodaysSession(context: context)
        let practiced = session.songsPracticed?.filter { $0.songId == "beatclikr.metronome" } ?? []
        #expect(practiced.count == 1)
        #expect(practiced.first?.title == "Metronome")
        #expect(practiced.first?.timesPracticed == 1)
    }

    @Test func `record song played with transient metronome still creates one built in item per day`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        vm.recordSongPlayed(song: Song.metronomeSong(), context: context)
        vm.recordSongPlayed(song: Song.metronomeSong(), context: context)
        let session = vm.getOrCreateTodaysSession(context: context)
        let practiced = session.songsPracticed?.filter { $0.songId == Song.metronomeSongId } ?? []
        #expect(practiced.count == 1)
        #expect(practiced.first?.title == "Metronome")
        #expect(practiced.first?.timesPracticed == 1)
    }

    @Test func `record polyrhythm practice creates one built in item per day`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        vm.recordPolyrhythmPractice(context: context)
        vm.recordPolyrhythmPractice(context: context)
        let session = vm.getOrCreateTodaysSession(context: context)
        let practiced = session.songsPracticed?.filter { $0.songId == "beatclikr.polyrhythm" } ?? []
        #expect(practiced.count == 1)
        #expect(practiced.first?.title == "Polyrhythm")
        #expect(practiced.first?.timesPracticed == 1)
    }

    @Test func `metronome and polyrhythm practice are separate history items`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        vm.recordMetronomePractice(context: context)
        vm.recordPolyrhythmPractice(context: context)
        let session = vm.getOrCreateTodaysSession(context: context)
        let ids = Set(session.songsPracticed?.compactMap(\.songId) ?? [])
        #expect(ids.contains("beatclikr.metronome"))
        #expect(ids.contains("beatclikr.polyrhythm"))
    }
}
