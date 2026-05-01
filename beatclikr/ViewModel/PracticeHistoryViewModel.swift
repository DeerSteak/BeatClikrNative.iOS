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
}
