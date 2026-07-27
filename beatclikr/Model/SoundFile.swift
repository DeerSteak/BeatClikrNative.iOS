//
//  SoundFile.swift
//  beatclikr
//
//  Created by Ben Funk on 8/13/23.
//

import AVFoundation
import OSLog

struct SoundFile {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BeatClikr", category: "Playback")
    var displayName: String
    var fileName: String
    var midiNote: Int
    var audioFile: AVAudioFile?

    init(_ prettyName: String, file: String, note: Int, bank: SoundBank = .acoustic) {
        displayName = prettyName
        fileName = file
        midiNote = note

        guard let url = Self.url(for: file, bank: bank) else { return }
        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch {
            Self.logger.error("Could not load \(file, privacy: .public): \(error, privacy: .public)")
        }
    }

    private static func url(for file: String, bank: SoundBank) -> URL? {
        let fileURL = URL(fileURLWithPath: file)
        let resourceName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension

        return Bundle.main.url(
            forResource: resourceName,
            withExtension: fileExtension,
            subdirectory: "Sounds/\(bank.rawValue)",
        )
    }
}
