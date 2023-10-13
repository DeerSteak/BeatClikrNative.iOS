//
//  SettingsViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 10/12/23.
//

import Foundation

class SettingsViewModel: ObservableObject {
    private let defaults: UserDefaultsService = UserDefaultsService.instance
    
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
    }
}
