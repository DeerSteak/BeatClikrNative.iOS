//
//  PracticeHistoryViewModelTests.swift
//  beatclikrTests
//
//  Created by Ben Funk on 5/1/26.
//

import Testing
import Foundation
import SwiftData
@testable import BeatClikr

@MainActor
struct PracticeHistoryViewModelTests {

    private let cal = Calendar.current
    private var today: Date { cal.startOfDay(for: .now) }
    private func daysAgo(_ n: Int) -> Date {
        cal.date(byAdding: .day, value: -n, to: today)!
    }

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Song.self, PracticeSession.self, PracticedSong.self,
            configurations: config
        )
    }

    // MARK: - currentStreak

    @Test func currentStreakIsZeroForEmptyDates() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.currentStreak(from: []) == 0)
    }

    @Test func currentStreakIsTodayOnly() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.currentStreak(from: [today]) == 1)
    }

    @Test func currentStreakCountsTodayAndYesterday() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.currentStreak(from: [today, daysAgo(1)]) == 2)
    }

    @Test func currentStreakCountsThreeConsecutiveDays() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [today, daysAgo(1), daysAgo(2)]
        #expect(vm.currentStreak(from: dates) == 3)
    }

    @Test func currentStreakCountsFromYesterdayWhenTodayMissing() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(1), daysAgo(2)]
        #expect(vm.currentStreak(from: dates) == 2)
    }

    @Test func currentStreakIsZeroWhenGapBeforeYesterday() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(3), daysAgo(4)]
        #expect(vm.currentStreak(from: dates) == 0)
    }

    @Test func currentStreakNotExtendedByNonConsecutiveDate() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [today, daysAgo(3)]
        #expect(vm.currentStreak(from: dates) == 1)
    }

    // MARK: - practiceReminderNeeded

    @Test func practiceReminderNeededIsFalseForEmptyDates() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.practiceReminderNeeded(from: []) == false)
    }

    @Test func practiceReminderNeededIsFalseWhenPracticedToday() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.practiceReminderNeeded(from: [today]) == false)
    }

    @Test func practiceReminderNeededIsTrueWhenLastPracticeWasYesterday() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.practiceReminderNeeded(from: [daysAgo(1)]) == true)
    }

    @Test func practiceReminderNeededIsTrueForMultiDayStreakEndingYesterday() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(1), daysAgo(2), daysAgo(3)]
        #expect(vm.practiceReminderNeeded(from: dates) == true)
    }

    @Test func practiceReminderNeededIsFalseWhenNoActiveStreak() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(3), daysAgo(4)]
        #expect(vm.practiceReminderNeeded(from: dates) == false)
    }

    // MARK: - currentStreakStartDate

    @Test func currentStreakStartDateIsNilForEmptyDates() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.currentStreakStartDate(from: []) == nil)
    }

    @Test func currentStreakStartDateIsTodayForSingleDayStreak() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.currentStreakStartDate(from: [today]) == today)
    }

    @Test func currentStreakStartDateIsCorrectForMultiDayStreak() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [today, daysAgo(1), daysAgo(2)]
        #expect(vm.currentStreakStartDate(from: dates) == daysAgo(2))
    }

    // MARK: - longestStreak

    @Test func longestStreakIsZeroForEmptyDates() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.longestStreak(from: []) == 0)
    }

    @Test func longestStreakIsOneForSingleDate() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.longestStreak(from: [today]) == 1)
    }

    @Test func longestStreakIsOneForNonConsecutiveDates() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [today, daysAgo(5), daysAgo(10)]
        #expect(vm.longestStreak(from: dates) == 1)
    }

    @Test func longestStreakCountsConsecutiveDays() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(1), daysAgo(2), daysAgo(3), daysAgo(4)]
        #expect(vm.longestStreak(from: dates) == 4)
    }

    @Test func longestStreakPicksLongestRun() {
        let vm = PracticeHistoryViewModel()
        let shortRun: Set<Date> = [daysAgo(20), daysAgo(21)]
        let longRun: Set<Date> = [daysAgo(5), daysAgo(6), daysAgo(7), daysAgo(8)]
        #expect(vm.longestStreak(from: shortRun.union(longRun)) == 4)
    }

    // MARK: - longestStreakRange

    @Test func longestStreakRangeIsNilForEmptyDates() {
        let vm = PracticeHistoryViewModel()
        #expect(vm.longestStreakRange(from: []) == nil)
    }

    @Test func longestStreakRangeStartEqualsEndForSingleDate() {
        let vm = PracticeHistoryViewModel()
        let result = vm.longestStreakRange(from: [today])
        #expect(result?.start == today)
        #expect(result?.end == today)
    }

    @Test func longestStreakRangeReturnsCorrectBounds() {
        let vm = PracticeHistoryViewModel()
        let dates: Set<Date> = [daysAgo(2), daysAgo(3), daysAgo(4)]
        let result = vm.longestStreakRange(from: dates)
        #expect(result?.start == daysAgo(4))
        #expect(result?.end == daysAgo(2))
    }

    // MARK: - markedDates

    @Test func markedDatesIsEmptyWithNoSessions() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        #expect(vm.markedDates(context: context).isEmpty)
    }

    @Test func markedDatesContainsSessionDates() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let session = PracticeSession(date: today)
        context.insert(session)
        let vm = PracticeHistoryViewModel()
        let dates = vm.markedDates(context: context)
        #expect(dates.contains(today))
        #expect(dates.count == 1)
    }

    @Test func markedDatesNormalizesToStartOfDay() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: today)!
        let session = PracticeSession(date: noon)
        context.insert(session)
        let vm = PracticeHistoryViewModel()
        #expect(vm.markedDates(context: context).contains(today))
    }

    // MARK: - session(for:context:)

    @Test func sessionForDateReturnsMatchingSession() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let session = PracticeSession(date: today)
        context.insert(session)
        let vm = PracticeHistoryViewModel()
        let found = vm.session(for: today, context: context)
        #expect(found != nil)
        #expect(found?.id == session.id)
    }

    @Test func sessionForDateReturnsNilWhenNotFound() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        #expect(vm.session(for: today, context: context) == nil)
    }

    @Test func sessionForDateDoesNotReturnWrongDaySession() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let session = PracticeSession(date: daysAgo(1))
        context.insert(session)
        let vm = PracticeHistoryViewModel()
        #expect(vm.session(for: today, context: context) == nil)
    }

    // MARK: - getOrCreateTodaysSession

    @Test func getOrCreateTodaysSessionCreatesNewSession() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        let session = vm.getOrCreateTodaysSession(context: context)
        #expect(session.date != nil)
        #expect(cal.isDateInToday(session.date!))
    }

    @Test func getOrCreateTodaysSessionReturnsExistingSession() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = PracticeHistoryViewModel()
        let first = vm.getOrCreateTodaysSession(context: context)
        let second = vm.getOrCreateTodaysSession(context: context)
        #expect(first.id == second.id)
    }

    // MARK: - recordSongPlayed

    @Test func recordSongPlayedCreatesNewPracticedSong() throws {
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

    @Test func recordSongPlayedIncrementsTimesPlayedOnRepeat() throws {
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

    @Test func recordSongPlayedCopiesSongMetadata() throws {
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
}
