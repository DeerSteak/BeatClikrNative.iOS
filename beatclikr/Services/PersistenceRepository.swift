//
//  PersistenceRepository.swift
//  beatclikr
//
//  Created by Ben Funk on 7/27/26.
//

import Foundation
import SwiftData

enum PersistenceFailure: LocalizedError {
    case fetch(underlying: Error)
    case save(underlying: Error)
    case validation(message: String)
    case conflict(message: String)

    var errorDescription: String? {
        switch self {
        case .fetch:
            String(localized: "Your data could not be loaded.")
        case .save:
            String(localized: "Your changes could not be saved.")
        case let .validation(message), let .conflict(message):
            message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetch, .save:
            String(localized: "Please try again. Your previous saved data is unchanged.")
        case .validation:
            String(localized: "Correct the highlighted information and try again.")
        case .conflict:
            String(localized: "Review the existing items and try again.")
        }
    }
}

@MainActor
protocol PersistenceRepository {
    func fetch<Model: PersistentModel>(
        _ descriptor: FetchDescriptor<Model>,
        from context: ModelContext,
    ) -> Result<[Model], PersistenceFailure>
    func save(_ context: ModelContext) -> Result<Void, PersistenceFailure>
}

@MainActor
struct SwiftDataPersistenceRepository: PersistenceRepository {
    func fetch<Model: PersistentModel>(
        _ descriptor: FetchDescriptor<Model>,
        from context: ModelContext,
    ) -> Result<[Model], PersistenceFailure> {
        do {
            return try .success(context.fetch(descriptor))
        } catch {
            return .failure(.fetch(underlying: error))
        }
    }

    func save(_ context: ModelContext) -> Result<Void, PersistenceFailure> {
        do {
            try context.save()
            return .success(())
        } catch {
            context.rollback()
            return .failure(.save(underlying: error))
        }
    }
}
