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
    
    func getInstantRhythm() -> FileConstants {
        let val = defaults.string(forKey: PreferenceKeys.InstantRhythm) ?? FileConstants.ClickLo.rawValue
        return FileConstants(rawValue: val) ?? FileConstants.ClickLo
    }
    
    func setInstantRhythm(val: FileConstants) {
        defaults.setValue(val.rawValue, forKey: PreferenceKeys.InstantRhythm)
    }
    
    func getInstantBeat() -> FileConstants {
        let val = defaults.string(forKey: PreferenceKeys.InstantBeat) ?? FileConstants.ClickLo.rawValue
        return FileConstants(rawValue: val) ?? FileConstants.ClickLo
    }
    
    func setInstantBeat(val: FileConstants) {
        defaults.setValue(val.rawValue, forKey: PreferenceKeys.InstantBeat)
    }    
    
    func getInstantGroove() -> Groove {
        let val = defaults.integer(forKey: PreferenceKeys.InstantSelectedSubdivisionIndex)
        return Groove(rawValue: val) ?? Groove.eighth
    }
    
    func setInstantGroove(val: Groove) {
        defaults.setValue(val.rawValue, forKey: PreferenceKeys.InstantSelectedSubdivisionIndex)
    }
    
    func getInstantBpm() -> Double {
        let val = defaults.double(forKey: PreferenceKeys.InstantBpm)
        if val >= 30 && val <= 240 {
            return val
        }
        return 60
    }
    
    func setInstantBpm(val: Double) {
        defaults.setValue(val, forKey: PreferenceKeys.InstantBpm)
    }

    func getPlaylistRhythm() -> FileConstants {
        let val = defaults.string(forKey: PreferenceKeys.PlaylistRhythm) ?? FileConstants.ClickLo.rawValue
        return FileConstants(rawValue: val) ?? FileConstants.ClickLo
    }
    
    func setPlaylistRhythm(val: FileConstants) {
        defaults.setValue(val.rawValue, forKey: PreferenceKeys.PlaylistRhythm)
    }
    
    func getPlaylistBeat() -> FileConstants {
        let val = defaults.string(forKey: PreferenceKeys.PlaylistBeat) ?? FileConstants.ClickLo.rawValue
        return FileConstants(rawValue: val) ?? FileConstants.ClickLo
    }
    
    func setPlaylistBeat(val: FileConstants) {
        defaults.setValue(val.rawValue, forKey: PreferenceKeys.PlaylistBeat)
    }
    
    //MARK: Vibration preferences
    func getUseVibration() -> Bool {
        return defaults.object(forKey: PreferenceKeys.UseHaptic) as? Bool ?? true
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
        return defaults.object(forKey: PreferenceKeys.ReminderTime) as? Date ?? Date.now
    }
    
    func setReminderTime(val: Date) {
        defaults.setValue(val, forKey: PreferenceKeys.ReminderTime)
    }
}
