//
//  UserDefaultsService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/6/23.
//

import Foundation
import AVFoundation

@MainActor
class UserDefaultsService: ObservableObject {
    @Published var useFlashlight: Bool {
        didSet {
            defaults.setValue(useFlashlight, forKey: PreferenceKeys.useFlashlight)
            cloud.set(useFlashlight, forKey: PreferenceKeys.useFlashlight)
        }
    }
    @Published var useVibration: Bool {
        didSet {
            defaults.setValue(useVibration, forKey: PreferenceKeys.useHaptic)
            cloud.set(useVibration, forKey: PreferenceKeys.useHaptic)
        }
    }
    @Published var muteMetronome: Bool {
        didSet {
            defaults.setValue(muteMetronome, forKey: PreferenceKeys.muteMetronome)
            cloud.set(muteMetronome, forKey: PreferenceKeys.muteMetronome)
        }
    }

    @Published var instantBeat: FileConstants {
        didSet {
            defaults.setValue(instantBeat.rawValue, forKey: PreferenceKeys.instantBeat)
            cloud.set(instantBeat.rawValue, forKey: PreferenceKeys.instantBeat)
        }
    }
    @Published var instantBpm: Double {
        didSet {
            defaults.setValue(instantBpm, forKey: PreferenceKeys.instantBpm)
            cloud.set(instantBpm, forKey: PreferenceKeys.instantBpm)
        }
    }
    @Published var instantGroove: Groove {
        didSet {
            defaults.setValue(instantGroove.rawValue, forKey: PreferenceKeys.instantGroove)
            cloud.set(instantGroove.rawValue, forKey: PreferenceKeys.instantGroove)
        }
    }
    @Published var instantRhythm: FileConstants {
        didSet {
            defaults.setValue(instantRhythm.rawValue, forKey: PreferenceKeys.instantRhythm)
            cloud.set(instantRhythm.rawValue, forKey: PreferenceKeys.instantRhythm)
        }
    }

    @Published var playlistBeat: FileConstants {
        didSet {
            defaults.setValue(playlistBeat.rawValue, forKey: PreferenceKeys.playlistBeat)
            cloud.set(playlistBeat.rawValue, forKey: PreferenceKeys.playlistBeat)
        }
    }
    @Published var playlistRhythm: FileConstants {
        didSet {
            defaults.setValue(playlistRhythm.rawValue, forKey: PreferenceKeys.playlistRhythm)
            cloud.set(playlistRhythm.rawValue, forKey: PreferenceKeys.playlistRhythm)
        }
    }

    @Published var sendReminders: Bool {
        didSet {
            defaults.setValue(sendReminders, forKey: PreferenceKeys.sendReminders)
            cloud.set(sendReminders, forKey: PreferenceKeys.sendReminders)
        }
    }
    @Published var reminderTime: Date {
        didSet {
            defaults.set(reminderTime.timeIntervalSinceReferenceDate, forKey: PreferenceKeys.reminderTime)
            cloud.set(reminderTime.timeIntervalSinceReferenceDate, forKey: PreferenceKeys.reminderTime)
        }
    }

    private let defaults = UserDefaults.standard
    private let cloud = NSUbiquitousKeyValueStore.default

    static let instance = UserDefaultsService()

    init() {
        useFlashlight = defaults.bool(forKey: PreferenceKeys.useFlashlight)
        useVibration = defaults.bool(forKey: PreferenceKeys.useHaptic)
        muteMetronome = defaults.bool(forKey: PreferenceKeys.muteMetronome)

        instantBeat = FileConstants(rawValue: defaults.string(forKey: PreferenceKeys.instantBeat) ?? "") ?? FileConstants.ClickHi
        instantRhythm = FileConstants(rawValue: defaults.string(forKey: PreferenceKeys.instantRhythm) ?? "") ?? FileConstants.ClickLo
        let bpm = defaults.double(forKey: PreferenceKeys.instantBpm)
        instantBpm = bpm == 0 ? 60 : bpm
        instantGroove = Groove(rawValue: defaults.integer(forKey: PreferenceKeys.instantGroove)) ?? .quarter

        playlistBeat = FileConstants(rawValue: defaults.string(forKey: PreferenceKeys.playlistBeat) ?? "") ?? FileConstants.ClickHi
        playlistRhythm = FileConstants(rawValue: defaults.string(forKey: PreferenceKeys.playlistRhythm) ?? "") ?? FileConstants.ClickLo

        sendReminders = defaults.bool(forKey: PreferenceKeys.sendReminders)
        let storedInterval = defaults.double(forKey: PreferenceKeys.reminderTime)
        reminderTime = storedInterval == 0 ? Date.now : Date(timeIntervalSinceReferenceDate: storedInterval)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud
        )
        cloud.synchronize()
    }

    @objc private func cloudStoreDidChange(_ notification: Notification) {
        Task { @MainActor in
            self.useFlashlight = cloud.bool(forKey: PreferenceKeys.useFlashlight)
            self.useVibration = cloud.bool(forKey: PreferenceKeys.useHaptic)
            self.muteMetronome = cloud.bool(forKey: PreferenceKeys.muteMetronome)

            self.instantBeat = FileConstants(rawValue: cloud.string(forKey: PreferenceKeys.instantBeat) ?? "") ?? .ClickHi
            self.instantRhythm = FileConstants(rawValue: cloud.string(forKey: PreferenceKeys.instantRhythm) ?? "") ?? .ClickLo
            let bpm = cloud.double(forKey: PreferenceKeys.instantBpm)
            self.instantBpm = bpm == 0 ? 60 : bpm
            self.instantGroove = Groove(rawValue: Int(cloud.longLong(forKey: PreferenceKeys.instantGroove))) ?? .quarter

            self.playlistBeat = FileConstants(rawValue: cloud.string(forKey: PreferenceKeys.playlistBeat) ?? "") ?? .ClickHi
            self.playlistRhythm = FileConstants(rawValue: cloud.string(forKey: PreferenceKeys.playlistRhythm) ?? "") ?? .ClickLo

            self.sendReminders = cloud.bool(forKey: PreferenceKeys.sendReminders)
            let cloudInterval = cloud.double(forKey: PreferenceKeys.reminderTime)
            if cloudInterval != 0 {
                self.reminderTime = Date(timeIntervalSinceReferenceDate: cloudInterval)
            }
        }
    }
}
