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
            guard oldValue != useFlashlight else { return }
            defaults.setValue(useFlashlight, forKey: PreferenceKeys.useFlashlight)
            cloud.set(useFlashlight, forKey: PreferenceKeys.useFlashlight)
        }
    }
    
    @Published var useVibration: Bool {
        didSet {
            guard oldValue != useVibration else { return }
            defaults.setValue(useVibration, forKey: PreferenceKeys.useHaptic)
            cloud.set(useVibration, forKey: PreferenceKeys.useHaptic)
        }
    }
    
    @Published var muteMetronome: Bool {
        didSet {
            guard oldValue != muteMetronome else { return }
            defaults.setValue(muteMetronome, forKey: PreferenceKeys.muteMetronome)
            cloud.set(muteMetronome, forKey: PreferenceKeys.muteMetronome)
        }
    }
    
    @Published var instantBeat: FileConstants {
        didSet {
            guard oldValue != instantBeat else { return }
            defaults.setValue(instantBeat.rawValue, forKey: PreferenceKeys.instantBeat)
            cloud.set(instantBeat.rawValue, forKey: PreferenceKeys.instantBeat)
        }
    }
    
    @Published var instantBpm: Double {
        didSet {
            guard oldValue != instantBpm else { return }
            defaults.setValue(instantBpm, forKey: PreferenceKeys.instantBpm)
            cloud.set(instantBpm, forKey: PreferenceKeys.instantBpm)
        }
    }
    
    @Published var instantGroove: Groove {
        didSet {
            guard oldValue != instantGroove else { return }
            defaults.setValue(instantGroove.rawValue, forKey: PreferenceKeys.instantGroove)
            cloud.set(instantGroove.rawValue, forKey: PreferenceKeys.instantGroove)
        }
    }
    
    @Published var instantRhythm: FileConstants {
        didSet {
            guard oldValue != instantRhythm else { return }
            defaults.setValue(instantRhythm.rawValue, forKey: PreferenceKeys.instantRhythm)
            cloud.set(instantRhythm.rawValue, forKey: PreferenceKeys.instantRhythm)
        }
    }
    
    @Published var playlistBeat: FileConstants {
        didSet {
            guard oldValue != playlistBeat else { return }
            defaults.setValue(playlistBeat.rawValue, forKey: PreferenceKeys.playlistBeat)
            cloud.set(playlistBeat.rawValue, forKey: PreferenceKeys.playlistBeat)
        }
    }
    
    @Published var playlistRhythm: FileConstants {
        didSet {
            guard oldValue != playlistRhythm else { return }
            defaults.setValue(playlistRhythm.rawValue, forKey: PreferenceKeys.playlistRhythm)
            cloud.set(playlistRhythm.rawValue, forKey: PreferenceKeys.playlistRhythm)
        }
    }
    
    @Published var sendReminders: Bool {
        didSet {
            guard oldValue != sendReminders else { return }
            defaults.setValue(sendReminders, forKey: PreferenceKeys.sendReminders)
            cloud.set(sendReminders, forKey: PreferenceKeys.sendReminders)
        }
    }
    
    @Published var reminderTime: Date {
        didSet {
            guard oldValue != reminderTime else { return }
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
    
    @objc @MainActor
    private func cloudStoreDidChange(_ notification: Notification) {
        cloud.synchronize()
        
        self.useFlashlight = cloud.bool(forKey: PreferenceKeys.useFlashlight)
        self.useVibration = cloud.bool(forKey: PreferenceKeys.useHaptic)
        self.muteMetronome = cloud.bool(forKey: PreferenceKeys.muteMetronome)
        
        self.instantBeat = FileConstants(rawValue: cloud.string(forKey: PreferenceKeys.instantBeat) ?? "") ?? .ClickHi
        self.instantRhythm = FileConstants(rawValue: cloud.string(forKey: PreferenceKeys.instantRhythm) ?? "") ?? .ClickLo
        
        let bpm = cloud.double(forKey: PreferenceKeys.instantBpm)
        self.instantBpm = bpm == 0 ? 60 : bpm
        
        let grooveRaw = Int(cloud.longLong(forKey: PreferenceKeys.instantGroove))
        self.instantGroove = Groove(rawValue: grooveRaw) ?? .quarter
        
        self.playlistBeat = FileConstants(rawValue: cloud.string(forKey: PreferenceKeys.playlistBeat) ?? "") ?? .ClickHi
        self.playlistRhythm = FileConstants(rawValue: cloud.string(forKey: PreferenceKeys.playlistRhythm) ?? "") ?? .ClickLo
        
        self.sendReminders = cloud.bool(forKey: PreferenceKeys.sendReminders)
        let cloudInterval = cloud.double(forKey: PreferenceKeys.reminderTime)
        if cloudInterval != 0 {
            self.reminderTime = Date(timeIntervalSinceReferenceDate: cloudInterval)
        }
    }
}
