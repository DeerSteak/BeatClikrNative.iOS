//
//  PlaybackState.swift
//  beatclikr
//

import Foundation

enum PlaybackState: Equatable {
    case idle
    case preparing
    case playing
    case interrupted
    case failed(PlaybackError)

    var canPause: Bool {
        self == .playing || self == .preparing
    }
}

enum PlaybackError: Error, Equatable, LocalizedError {
    case audioSessionUnavailable
    case engineStartFailed
    case audioFormatMismatch
    case soundNotFound(String)
    case soundUnreadable(String)
    case soundConversionFailed(String)
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .audioSessionUnavailable:
            String(localized: "BeatClikr couldn't access the audio system.")
        case .engineStartFailed:
            String(localized: "BeatClikr couldn't start the audio engine.")
        case .audioFormatMismatch:
            String(localized: "BeatClikr couldn't match the current audio output format.")
        case let .soundNotFound(name):
            String(localized: "The selected sound “\(name)” is missing.")
        case let .soundUnreadable(name):
            String(localized: "The selected sound “\(name)” couldn't be read.")
        case let .soundConversionFailed(name):
            String(localized: "The selected sound “\(name)” isn't compatible with the current audio output.")
        case .invalidConfiguration:
            String(localized: "The selected tempo or rhythm isn't valid.")
        }
    }
}
