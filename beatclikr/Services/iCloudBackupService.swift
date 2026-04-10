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
        var version: Int
        var timestamp: Date
        var settings: SettingsBackup?
        var songs: [SongBackup]?
        var playlistEntries: [PlaylistEntryBackup]?

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
            let groove: Int
        }

        struct PlaylistEntryBackup: Codable {
            let id: String
            let songId: String
            let sequence: Int
        }
    }

    // MARK: - iCloud Directory

    private var iCloudURL: URL? {
        fileManager.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
    }

    // MARK: - Read/Write Helpers

    private func readBackup() throws -> BackupData? {
        guard let iCloudURL = iCloudURL else { return nil }
        let backupURL = iCloudURL.appendingPathComponent(backupFileName)
        guard fileManager.fileExists(atPath: backupURL.path) else { return nil }

        let data = try Data(contentsOf: backupURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupData.self, from: data)
    }

    private func writeBackup(_ backup: BackupData) throws {
        guard let iCloudURL = iCloudURL else {
            throw BackupError.iCloudNotAvailable
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(backup)

        if !fileManager.fileExists(atPath: iCloudURL.path) {
            try fileManager.createDirectory(at: iCloudURL, withIntermediateDirectories: true)
        }

        let backupURL = iCloudURL.appendingPathComponent(backupFileName)
        try data.write(to: backupURL)
    }

    // MARK: - Individual Backup Methods

    func backupSettings(_ settings: UserDefaultsService) async throws {
        var backup = (try? readBackup()) ?? BackupData(version: 1, timestamp: Date())
        backup.timestamp = Date()
        backup.settings = BackupData.SettingsBackup(
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
        )
        try writeBackup(backup)
    }

    func backupSongs(_ songs: [Song]) async throws {
        var backup = (try? readBackup()) ?? BackupData(version: 1, timestamp: Date())
        backup.timestamp = Date()
        backup.songs = songs.map { song in
            BackupData.SongBackup(
                id: song.id,
                title: song.title,
                artist: song.artist,
                beatsPerMinute: song.beatsPerMinute,
                beatsPerMeasure: song.beatsPerMeasure,
                groove: song.groove.rawValue
            )
        }
        try writeBackup(backup)
    }

    func backupPlaylistEntries(_ entries: [PlaylistEntry]) async throws {
        var backup = (try? readBackup()) ?? BackupData(version: 1, timestamp: Date())
        backup.timestamp = Date()
        backup.playlistEntries = entries.compactMap { entry in
            guard let song = entry.song else { return nil }
            return BackupData.PlaylistEntryBackup(
                id: entry.id,
                songId: song.id,
                sequence: entry.sequence
            )
        }
        try writeBackup(backup)
    }

    // MARK: - Restore

    func restoreFromiCloud(settings: UserDefaultsService, modelContext: ModelContext) async throws {
        guard let backup = try readBackup() else {
            throw BackupError.backupNotFound
        }

        // Restore settings
        if let settingsBackup = backup.settings {
            settings.useFlashlight = settingsBackup.useFlashlight
            settings.useVibration = settingsBackup.useVibration
            settings.muteMetronome = settingsBackup.muteMetronome
            settings.instantBeat = FileConstants(rawValue: settingsBackup.instantBeat) ?? .ClickHi
            settings.instantBpm = settingsBackup.instantBpm
            settings.instantGroove = Groove(rawValue: settingsBackup.instantGroove) ?? .quarter
            settings.instantRhythm = FileConstants(rawValue: settingsBackup.instantRhythm) ?? .ClickLo
            settings.playlistBeat = FileConstants(rawValue: settingsBackup.playlistBeat) ?? .ClickHi
            settings.playlistRhythm = FileConstants(rawValue: settingsBackup.playlistRhythm) ?? .ClickLo
            settings.sendReminders = settingsBackup.sendReminders
            settings.reminderTime = settingsBackup.reminderTime
        }

        // Delete existing playlist entries first (they reference songs)
        let entryDescriptor = FetchDescriptor<PlaylistEntry>()
        let existingEntries = try modelContext.fetch(entryDescriptor)
        for entry in existingEntries {
            modelContext.delete(entry)
        }

        // Delete existing songs
        let descriptor = FetchDescriptor<Song>()
        let existingSongs = try modelContext.fetch(descriptor)
        for song in existingSongs {
            modelContext.delete(song)
        }

        // Insert backed up songs
        var songMap: [String: Song] = [:]
        if let songBackups = backup.songs {
            for songBackup in songBackups {
                let song = Song(
                    title: songBackup.title,
                    artist: songBackup.artist,
                    beatsPerMinute: songBackup.beatsPerMinute,
                    beatsPerMeasure: songBackup.beatsPerMeasure,
                    groove: Groove(rawValue: songBackup.groove) ?? .quarter
                )
                song.id = songBackup.id
                modelContext.insert(song)
                songMap[song.id] = song
            }
        }

        // Insert backed up playlist entries
        if let entryBackups = backup.playlistEntries {
            for entryBackup in entryBackups {
                if let song = songMap[entryBackup.songId] {
                    let entry = PlaylistEntry(song: song, sequence: entryBackup.sequence)
                    entry.id = entryBackup.id
                    modelContext.insert(entry)
                }
            }
        }

        try modelContext.save()
    }

    // MARK: - Utilities

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
