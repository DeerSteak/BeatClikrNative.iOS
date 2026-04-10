//
//  SettingsViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 10/12/23.
//

import Foundation
import SwiftData

@MainActor
class SettingsViewModel: ObservableObject {
    private let defaults: UserDefaultsService = UserDefaultsService.instance
    private let backupService = iCloudBackupService.shared

    @Published var isBackingUp = false
    @Published var isRestoring = false
    @Published var lastBackupDate: Date?
    @Published var backupError: String?
    @Published var backupSuccess: String?
    
    @Published var sendReminders: Bool {
        didSet {
            defaults.sendReminders = sendReminders
        }
    }
    
    @Published var useFlashlight: Bool {
        didSet {
            defaults.useFlashlight = useFlashlight
        }
    }
    
    @Published var useVibration: Bool {
        didSet {
            defaults.useVibration = useVibration
        }
    }
    
    @Published var muteMetronome: Bool {
        didSet {
            defaults.muteMetronome = muteMetronome
        }
    }
    
    @Published var instantBeat: FileConstants {
        didSet {
            defaults.instantBeat = instantBeat
        }
    }
    
    @Published var instantRhythm: FileConstants {
        didSet {
            defaults.instantRhythm = instantRhythm
        }
    }
    
    @Published var playlistBeat: FileConstants {
        didSet {
            defaults.playlistBeat = playlistBeat
        }
    }
    
    @Published var playlistRhythm: FileConstants {
        didSet {
            defaults.playlistRhythm = playlistRhythm
        }
    }
    
    init() {
        sendReminders = defaults.sendReminders
        useFlashlight = defaults.useFlashlight
        useVibration = defaults.useVibration
        muteMetronome = defaults.muteMetronome
        instantBeat = defaults.instantBeat
        instantRhythm = defaults.instantRhythm
        playlistBeat = defaults.playlistBeat
        playlistRhythm = defaults.playlistRhythm

        Task {
            lastBackupDate = await backupService.getLastBackupDate()
        }
    }

    // MARK: - Backup Methods

    func backupToiCloud(songs: [Song], playlistEntries: [PlaylistEntry]) {
        guard !isBackingUp else { return }

        isBackingUp = true
        backupError = nil
        backupSuccess = nil

        Task {
            do {
                try await backupService.backupSettings(defaults)
                try await backupService.backupSongs(songs)
                try await backupService.backupPlaylistEntries(playlistEntries)
                lastBackupDate = Date()
                backupSuccess = "Backup successful!"
            } catch {
                backupError = error.localizedDescription
            }
            isBackingUp = false
        }
    }

    func restoreFromiCloud(modelContext: ModelContext) {
        guard !isRestoring else { return }

        isRestoring = true
        backupError = nil
        backupSuccess = nil

        Task {
            do {
                try await backupService.restoreFromiCloud(settings: defaults, modelContext: modelContext)

                // Update published properties to reflect restored values
                sendReminders = defaults.sendReminders
                useFlashlight = defaults.useFlashlight
                useVibration = defaults.useVibration
                muteMetronome = defaults.muteMetronome
                instantBeat = defaults.instantBeat
                instantRhythm = defaults.instantRhythm
                playlistBeat = defaults.playlistBeat
                playlistRhythm = defaults.playlistRhythm

                backupSuccess = "Restore successful!"
            } catch {
                backupError = error.localizedDescription
            }
            isRestoring = false
        }
    }

    func checkiCloudAvailability() -> Bool {
        return backupService.checkiCloudAvailability()
    }
}
