//
//  PreferencesViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 8/6/23.
//

import Foundation
class PreferencesViewModel: ObservableObject {
    @Published var useFlashlight: Bool
    @Published var muteMetronome: Bool
    @Published var instantBeatName: String
    @Published var instantRhythmName: String
    @Published var playlistBeatName: String
    @Published var playlistRhythmName: String
    @Published var useVibration: Bool
    @Published var sendReminders: Bool
    @Published var reminderTime: Date
    
    var defaults = UserDefaultsService.instance
    
    init() {
        useFlashlight = defaults.getUseFlashlight()
        muteMetronome = defaults.getMuteMetronome()
        instantBeatName = defaults.getInstantBeat()
        instantRhythmName = defaults.getInstantRhythm()
        playlistBeatName = defaults.getPlaylistBeat()
        playlistRhythmName = defaults.getPlaylistRhythm()
        useVibration = defaults.getUseVibration()
        sendReminders = defaults.getSendReminders()
        reminderTime = defaults.getReminderTime()
    }
}
