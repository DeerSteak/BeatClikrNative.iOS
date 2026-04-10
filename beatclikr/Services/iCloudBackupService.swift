//
//  iCloudBackupService.swift
//  beatclikr
//
//  Created by Ben Funk on 4/10/26.
//

import Foundation
import SwiftData

@MainActor
class iCloudBackupService {
    static let shared = iCloudBackupService()

    private let backupFileName = "BeatClikrBackup.json"
    private let fileManager = FileManager.default

    // MARK: - Backup Data Structure

    struct BackupData: Codable {
        let version: Int
        let timestamp: Date
        let settings: SettingsBackup
        let songs: [SongBackup]

        struct SettingsBackup: Codable {
            let useFlashlight: Bool
            let useVibration: Bool
            let muteMetronome: Bool
            let instantBeat: String
            let instantBpm: Double
            let instantGroove: Int
            let instantRhythm: String
            let playlistBeat: String
            let playlistRhythm: String
            let sendReminders: Bool
            let reminderTime: Date
        }

        struct SongBackup: Codable {
            let id: String
            let title: String
            let artist: String
            let beatsPerMinute: Double
            let beatsPerMeasure: Int
            let liveSequence: Int?
            let rehearsalSequence: Int?
            let groove: Int
        }
    }

    // MARK: - iCloud Directory

    private var iCloudURL: URL? {
        fileManager.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
    }

    // MARK: - Backup Methods

    func backupToiCloud(settings: UserDefaultsService, songs: [Song]) async throws {
        guard let iCloudURL = iCloudURL else {
            throw BackupError.iCloudNotAvailable
        }

        // Create backup data
        let backup = BackupData(
            version: 1,
            timestamp: Date(),
            settings: BackupData.SettingsBackup(
                useFlashlight: settings.useFlashlight,
                useVibration: settings.useVibration,
                muteMetronome: settings.muteMetronome,
                instantBeat: settings.instantBeat.rawValue,
                instantBpm: settings.instantBpm,
                instantGroove: settings.instantGroove.rawValue,
                instantRhythm: settings.instantRhythm.rawValue,
                playlistBeat: settings.playlistBeat.rawValue,
                playlistRhythm: settings.playlistRhythm.rawValue,
                sendReminders: settings.sendReminders,
                reminderTime: settings.reminderTime
            ),
            songs: songs.map { song in
                BackupData.SongBackup(
                    id: song.id,
                    title: song.title,
                    artist: song.artist,
                    beatsPerMinute: song.beatsPerMinute,
                    beatsPerMeasure: song.beatsPerMeasure,
                    liveSequence: song.liveSequence,
                    rehearsalSequence: song.rehearsalSequence,
                    groove: song.groove.rawValue
                )
            }
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(backup)

        // Ensure iCloud directory exists
        if !fileManager.fileExists(atPath: iCloudURL.path) {
            try fileManager.createDirectory(at: iCloudURL, withIntermediateDirectories: true)
        }

        // Write to iCloud
        let backupURL = iCloudURL.appendingPathComponent(backupFileName)
        try data.write(to: backupURL)
    }

    func restoreFromiCloud(settings: UserDefaultsService, modelContext: ModelContext) async throws {
        guard let iCloudURL = iCloudURL else {
            throw BackupError.iCloudNotAvailable
        }

        let backupURL = iCloudURL.appendingPathComponent(backupFileName)

        guard fileManager.fileExists(atPath: backupURL.path) else {
            throw BackupError.backupNotFound
        }

        // Read and decode backup
        let data = try Data(contentsOf: backupURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)

        // Restore settings
        settings.useFlashlight = backup.settings.useFlashlight
        settings.useVibration = backup.settings.useVibration
        settings.muteMetronome = backup.settings.muteMetronome
        settings.instantBeat = FileConstants(rawValue: backup.settings.instantBeat) ?? .ClickHi
        settings.instantBpm = backup.settings.instantBpm
        settings.instantGroove = Groove(rawValue: backup.settings.instantGroove) ?? .quarter
        settings.instantRhythm = FileConstants(rawValue: backup.settings.instantRhythm) ?? .ClickLo
        settings.playlistBeat = FileConstants(rawValue: backup.settings.playlistBeat) ?? .ClickHi
        settings.playlistRhythm = FileConstants(rawValue: backup.settings.playlistRhythm) ?? .ClickLo
        settings.sendReminders = backup.settings.sendReminders
        settings.reminderTime = backup.settings.reminderTime

        // Restore songs (replace existing)
        // First, delete all existing songs
        let descriptor = FetchDescriptor<Song>()
        let existingSongs = try modelContext.fetch(descriptor)
        for song in existingSongs {
            modelContext.delete(song)
        }

        // Insert backed up songs
        for songBackup in backup.songs {
            let song = Song(
                title: songBackup.title,
                artist: songBackup.artist,
                beatsPerMinute: songBackup.beatsPerMinute,
                beatsPerMeasure: songBackup.beatsPerMeasure,
                groove: Groove(rawValue: songBackup.groove) ?? .quarter
            )
            song.id = songBackup.id
            song.liveSequence = songBackup.liveSequence
            song.rehearsalSequence = songBackup.rehearsalSequence
            modelContext.insert(song)
        }

        try modelContext.save()
    }

    func checkiCloudAvailability() -> Bool {
        return iCloudURL != nil
    }

    func getLastBackupDate() async -> Date? {
        guard let iCloudURL = iCloudURL else { return nil }
        let backupURL = iCloudURL.appendingPathComponent(backupFileName)

        guard fileManager.fileExists(atPath: backupURL.path) else { return nil }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: backupURL.path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }

    // MARK: - Errors

    enum BackupError: LocalizedError {
        case iCloudNotAvailable
        case backupNotFound
        case encodingFailed
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .iCloudNotAvailable:
                return "iCloud is not available. Please enable iCloud Drive in Settings."
            case .backupNotFound:
                return "No backup found in iCloud."
            case .encodingFailed:
                return "Failed to create backup data."
            case .decodingFailed:
                return "Failed to read backup data."
            }
        }
    }
}
