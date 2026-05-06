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
class PracticeHistoryViewModel : ObservableObject {
    var onPracticeRecorded: ((ModelContext) -> Void)?
    
    @Published var practiceDates: Set<Date> = []
    @Published var selectedDateSongs: [PracticedSong] = []
    
    var currentStreak: Int { currentStreak(from: practiceDates) }
    var longestStreak: Int { longestStreak(from: practiceDates) }
    var reminderNeeded: Bool { practiceReminderNeeded(from: practiceDates) }
    
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
        practiceDates = markedDates(context: context)
    }
    
    func loadSongs(for date: Date?, context: ModelContext) {
        guard let date else { selectedDateSongs = []; return }
        selectedDateSongs = session(for: date, context: context)?.songsPracticed ?? []
    }
    
    func recordSongPlayed(song: Song, context: ModelContext) {
        let session = getOrCreateTodaysSession(context: context)
        let existing = session.songsPracticed?.first(where: { $0.songId == song.id })
        if let existing {
            existing.timesPracticed = (existing.timesPracticed ?? 0) + 1
        } else {
            let practicedSong = PracticedSong(from: song)
            session.songsPracticed?.append(practicedSong)
        }
        try? context.save()
        loadPracticeDates(context: context)
        onPracticeRecorded?(context)
    }
    
    func getOrCreateTodaysSession(context: ModelContext) -> PracticeSession {
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let distantPast = Date.distantPast
        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { session in
                (session.date ?? distantPast) >= start && (session.date ?? distantPast) < end
            })
        
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        
        let session = PracticeSession(date: .now)
        context.insert(session)
        return session
    }
    
    func session(for date: Date, context: ModelContext) -> PracticeSession? {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let distantPast = Date.distantPast
        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { session in
                (session.date ?? distantPast) >= start && (session.date ?? distantPast) < end
            })
        return try? context.fetch(descriptor).first
    }
    
    func markedDates(context: ModelContext) -> Set<Date> {
        let descriptor = FetchDescriptor<PracticeSession>()
        let sessions = (try? context.fetch(descriptor)) ?? []
        return Set(sessions.compactMap { $0.date.map { Calendar.current.startOfDay(for: $0) } })
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
    
    func scheduledNotificationBodies(from dates: Set<Date>, days: Int) -> [String] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<days).map { d in
            projectedBody(from: dates, referenceDate: cal.date(byAdding: .day, value: d, to: today)!)
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
        for i in 1..<sorted.count {
            if let next = cal.date(byAdding: .day, value: 1, to: sorted[i - 1]),
               cal.isDate(next, inSameDayAs: sorted[i]) {
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
