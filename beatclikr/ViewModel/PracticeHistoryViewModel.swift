//
//  PracticeHistoryViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 5/1/26.
//

import Foundation
import SwiftData

@MainActor
class PracticeHistoryViewModel : ObservableObject {    
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
