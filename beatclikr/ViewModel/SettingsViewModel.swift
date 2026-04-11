//
//  SettingsViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 10/12/23.
//

import Foundation
import UserNotifications

@MainActor
class SettingsViewModel: ObservableObject {
    private let defaults: UserDefaultsService = UserDefaultsService.instance
    
    @Published var showPermissionDeniedAlert = false

    @Published var sendReminders: Bool {
        didSet {
            defaults.sendReminders = sendReminders
            if sendReminders {
                requestPermissionAndSchedule()
            } else {
                cancelReminder()
            }
        }
    }
    
    @Published var reminderTime: Date {
        didSet {
            defaults.reminderTime = reminderTime
            if sendReminders {
                scheduleReminder()
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
    }
    
    private func requestPermissionAndSchedule() {
        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .denied {
                sendReminders = false
                showPermissionDeniedAlert = true
                return
            }
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
            if granted {
                scheduleReminder()
            } else {
                sendReminders = false
            }
        }
    }
    
    private func scheduleReminder() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "PracticeReminderNotificationTitle")
        content.body = String(localized: "PracticeReminderNotificationBody")
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "practiceReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["practiceReminder"])
    }
}
