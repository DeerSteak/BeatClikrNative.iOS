//
//  UserDefaultsService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/6/23.
//

import Foundation
import AVFoundation

class UserDefaultsService: ObservableObject {
    @Published var useFlashlight: Bool {
        didSet {
            defaults.setValue(useFlashlight, forKey: PreferenceKeys.useFlashlight)
        }
    }
    @Published var useVibration: Bool {
        didSet {
            defaults.setValue(useVibration, forKey: PreferenceKeys.useHaptic)
        }
    }
    @Published var muteMetronome: Bool {
        didSet {
            defaults.setValue(muteMetronome, forKey: PreferenceKeys.muteMetronome)
        }
    }
    
    @Published var instantBeat: FileConstants {
        didSet {
            defaults.setValue(instantBeat.rawValue, forKey: PreferenceKeys.instantBeat)
        }
    }
    @Published var instantBpm: Double {
        didSet {
            defaults.setValue(instantBpm, forKey: PreferenceKeys.instantBpm)
        }
    }
    @Published var instantGroove: Groove {
        didSet {
            defaults.setValue(instantGroove.rawValue, forKey: PreferenceKeys.instantGroove)
        }
    }
    @Published var instantRhythm: FileConstants {
        didSet {
            defaults.setValue(instantRhythm.rawValue, forKey: PreferenceKeys.instantRhythm)
        }
    }
    
    @Published var playlistBeat: FileConstants {
        didSet {
            defaults.setValue(playlistBeat.rawValue, forKey: PreferenceKeys.playlistBeat)
        }
    }
    @Published var playlistRhythm: FileConstants {
        didSet {
            defaults.setValue(playlistRhythm.rawValue, forKey: PreferenceKeys.playlistRhythm)
        }
    }
    
    @Published var sendReminders: Bool {
        didSet {
            defaults.setValue(sendReminders, forKey: PreferenceKeys.sendReminders)
        }
    }
    @Published var reminderTime: Date {
        didSet {
            defaults.setValue(reminderTime, forKey: PreferenceKeys.reminderTime)
        }
    }

    private let defaults = UserDefaults.standard
    
    static var instance = UserDefaultsService()
    
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
        reminderTime = defaults.object(forKey: PreferenceKeys.reminderTime) as? Date ?? Date.now
    }
}
