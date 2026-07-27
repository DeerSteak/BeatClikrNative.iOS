//
//  PracticeHistoryRepository.swift
//  beatclikr
//
//  Created by Ben Funk on 7/27/26.
//

import SwiftData

@MainActor
struct PracticeHistoryRepository {
    private let persistence: any PersistenceRepository

    init(persistence: any PersistenceRepository = SwiftDataPersistenceRepository()) {
        self.persistence = persistence
    }

    func sessions(
        matching descriptor: FetchDescriptor<PracticeSession> = FetchDescriptor<PracticeSession>(),
        context: ModelContext,
    ) -> Result<[PracticeSession], PersistenceFailure> {
        persistence.fetch(descriptor, from: context)
    }

    func commit(context: ModelContext) -> Result<Void, PersistenceFailure> {
        persistence.save(context)
    }
}
