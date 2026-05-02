//
//  SettingsViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 10/12/23.
//

import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    private let defaults: UserDefaultsService = UserDefaultsService.instance
    private let notificationService = ReminderNotificationService()
    
    @Published var showPermissionDeniedAlert = false
    
    @Published var sendReminders: Bool {
        didSet {
            defaults.sendReminders = sendReminders
            if sendReminders {
                requestPermissionAndSchedule()
            } else {
                notificationService.cancel()
            }
        }
    }
    
    @Published var reminderTime: Date {
        didSet {
            defaults.reminderTime = reminderTime
            if sendReminders {
                notificationService.reschedule(at: reminderTime)
            }
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
    
    @Published var keepAwake: Bool {
        didSet {
            defaults.keepAwake = keepAwake
        }
    }
    
    @Published var sixteenthAlternate: Bool {
        didSet {
            defaults.sixteenthAlternate = sixteenthAlternate
        }
    }
    
    init() {
        sendReminders = defaults.sendReminders
        reminderTime = defaults.reminderTime
        useFlashlight = defaults.useFlashlight
        useVibration = defaults.useVibration
        muteMetronome = defaults.muteMetronome
        instantBeat = defaults.instantBeat
        instantRhythm = defaults.instantRhythm
        playlistBeat = defaults.playlistBeat
        playlistRhythm = defaults.playlistRhythm
        keepAwake = defaults.keepAwake
        sixteenthAlternate = defaults.sixteenthAlternate
    }
    
    private func requestPermissionAndSchedule() {
        Task { @MainActor in
            switch await notificationService.checkAndRequestAuthorization() {
            case .granted:
                notificationService.reschedule(at: reminderTime)
            case .denied:
                sendReminders = false
                showPermissionDeniedAlert = true
            case .notGranted:
                sendReminders = false
            }
        }
    }
    
    func rescheduleReminder(bodies: [String]) {
        guard sendReminders else { return }
        notificationService.schedule(bodies: bodies, at: reminderTime)
    }
}
