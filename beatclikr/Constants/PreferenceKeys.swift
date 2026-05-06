//
//  PreferenceKeys.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation

struct PreferenceKeys {

    // MARK: - Synced (UserDefaults + NSUbiquitousKeyValueStore)
    static let instantBeat = "InstantBeat"
    static let instantRhythm = "InstantRhythm"
    static let instantGroove = "InstantGroove"
    static let instantBeatPattern = "InstantBeatPattern"
    static let instantBpm = "InstantBpm"
    static let playlistBeat = "RehearsalBeat"
    static let playlistRhythm = "RehearsalRhythm"
    static let muteMetronome = "MuteMetronome"
    static let useFlashlight = "UseFlashlight"
    static let useHaptic = "UseHaptic"
    static let keepAwake = "KeepAwake"
    static let sixteenthAlternate = "SixteenthAlternate"
    static let sendReminders = "SendReminders"
    static let reminderTime = "ReminderTime"

    static let polyrhythmBeat = "PolyrhythmBeat"
    static let polyrhythmRhythm = "PolyrhythmRhythm"
    static let polyrhythmBeats = "PolyrhythmBeats"
    static let polyrhythmAgainst = "PolyrhythmAgainst"

    // MARK: - Local only (UserDefaults only, never synced)
    static let onboarded = "Onboarded"
    static let hasAskedFlashlight = "HasAskedFlashlight"
    static let hasAskedHaptic = "HasAskedHaptic"
    static let hasAskedReminders = "HasAskedReminders"
    static let didMigrateToMultiplePlaylists = "DidMigrateToMultiplePlaylists"
    static let remindersDeferredDate = "RemindersDeferredDate"
    static let playlistSortAscending = "PlaylistSortAscending"
}
