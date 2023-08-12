//
//  UserDefaultsService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/6/23.
//

import Foundation
import AVFoundation

class UserDefaultsService {
    
    static var instance = UserDefaultsService()
    
    private let defaults = UserDefaults.standard
    
    //MARK: Flashlight preferences
    
    func getUseFlashlight() -> Bool {
        return defaults.bool(forKey: PreferenceKeys.UseFlashlight)
    }
    
    func setUseFlashlight(val: Bool) {
        defaults.setValue(val, forKey: PreferenceKeys.UseFlashlight)
    }
    
    func getHasAskedFlashlight() -> Bool {
        return defaults.bool(forKey: PreferenceKeys.HasAskedFlashlight)
    }
    
    func setHasAskFlashlight(val: Bool) {
        defaults.setValue(val, forKey: PreferenceKeys.HasAskedFlashlight)
    }
    
    //MARK: Sound preferences
    func getMuteMetronome() -> Bool {
        return defaults.bool(forKey: PreferenceKeys.MuteMetronome)
    }
    
    func setMuteMetronome(val: Bool) {
        defaults.setValue(val, forKey: PreferenceKeys.MuteMetronome)
    }
    
    func getInstantRhythm() -> String {
        return defaults.string(forKey: PreferenceKeys.InstantRhythm) ?? FileConstants.ClickLo
    }
    
    func setInstantRhythm(val: String) {
        if (FileConstants.isValid(val: val)) {
            defaults.setValue(val, forKey: PreferenceKeys.InstantRhythm)
        }
    }
    
    func getInstantBeat() -> String {
        return defaults.string(forKey: PreferenceKeys.InstantBeat) ?? FileConstants.ClickHi
    }
    
    func setInstantBeat(val: String) {
        if (FileConstants.isValid(val: val)) {
            defaults.setValue(val, forKey: PreferenceKeys.InstantBeat)
        }
    }
    
    func getPlaylistRhythm() -> String {
        return defaults.string(forKey: PreferenceKeys.PlaylistRhythm) ?? FileConstants.ClickLo
    }
    
    func setPlaylistRhythm(val: String) {
        if (FileConstants.isValid(val: val)) {
            defaults.setValue(val, forKey: PreferenceKeys.PlaylistRhythm)
        }
    }
    
    func getPlaylistBeat() -> String {
        return defaults.string(forKey: PreferenceKeys.PlaylistBeat) ?? FileConstants.ClickHi
    }
    
    func setPlaylistBeat(val: String) {
        if (FileConstants.isValid(val: val)) {
            defaults.setValue(val, forKey: PreferenceKeys.PlaylistBeat)
        }
    }
    
    //MARK: Vibration preferences
    func getUseVibration() -> Bool {
        guard let useVibration = defaults.object(forKey: PreferenceKeys.UseHaptic) as? Bool else {
            return true
        }
        return useVibration
    }
    
    func setUseVibration(val: Bool) {
        defaults.setValue(val, forKey: PreferenceKeys.UseHaptic)
    }
    
    func getHasAskedHaptic() -> Bool {
        return defaults.bool(forKey: PreferenceKeys.HasAskedHaptic)
    }
    
    func setHasAskedHaptic(val: Bool) {
        defaults.setValue(val, forKey: PreferenceKeys.HasAskedHaptic)
    }
    
    //MARK: Local notification preferences
    func getSendReminders() -> Bool {
        return defaults.bool(forKey: PreferenceKeys.PracticeReminders)
    }
    
    func setSendReminders(val: Bool) {
        defaults.setValue(val, forKey: PreferenceKeys.PracticeReminders)
    }
    
    func getReminderTime() -> Date {
        guard 
            let date = defaults.object(forKey: PreferenceKeys.ReminderTime) as? Date else {
            return Date.now
        }
        return date
    }
    
    func setReminderTime(val: Date) {
        defaults.setValue(val, forKey: PreferenceKeys.ReminderTime)
    }
}
