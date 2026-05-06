//
//  SettingsViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 10/12/23.
//

import Foundation
import UIKit
import UserNotifications

@MainActor
class SettingsViewModel: ObservableObject {
    private let defaults: UserDefaultsService = .instance
    private let notificationService: any ReminderNotificationServicing

    @Published var showPermissionDeniedAlert = false
    @Published var notificationsBlockedLocally = false
    @Published var notificationsDeferredLocally = false
    @Published var showCrossDeviceReminderPrompt = false

    @Published var sendReminders: Bool {
        didSet {
            defaults.sendReminders = sendReminders
            if sendReminders {
                requestPermissionAndSchedule()
            } else {
                notificationsBlockedLocally = false
                clearDeferral()
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
        didSet { defaults.useFlashlight = useFlashlight }
    }

    @Published var useVibration: Bool {
        didSet { defaults.useVibration = useVibration }
    }

    @Published var muteMetronome: Bool {
        didSet { defaults.muteMetronome = muteMetronome }
    }

    @Published var instantBeat: FileConstants {
        didSet { defaults.instantBeat = instantBeat }
    }

    @Published var instantRhythm: FileConstants {
        didSet { defaults.instantRhythm = instantRhythm }
    }

    @Published var playlistBeat: FileConstants {
        didSet { defaults.playlistBeat = playlistBeat }
    }

    @Published var playlistRhythm: FileConstants {
        didSet { defaults.playlistRhythm = playlistRhythm }
    }

    @Published var polyrhythmBeat: FileConstants {
        didSet { defaults.polyrhythmBeat = polyrhythmBeat }
    }

    @Published var polyrhythmRhythm: FileConstants {
        didSet { defaults.polyrhythmRhythm = polyrhythmRhythm }
    }

    @Published var keepAwake: Bool {
        didSet { defaults.keepAwake = keepAwake }
    }

    @Published var sixteenthAlternate: Bool {
        didSet { defaults.sixteenthAlternate = sixteenthAlternate }
    }

    init(notificationService: any ReminderNotificationServicing = ReminderNotificationService()) {
        self.notificationService = notificationService
        sendReminders = defaults.sendReminders
        reminderTime = defaults.reminderTime
        useFlashlight = defaults.useFlashlight
        useVibration = defaults.useVibration
        muteMetronome = defaults.muteMetronome
        instantBeat = defaults.instantBeat
        instantRhythm = defaults.instantRhythm
        playlistBeat = defaults.playlistBeat
        playlistRhythm = defaults.playlistRhythm
        polyrhythmBeat = defaults.polyrhythmBeat
        polyrhythmRhythm = defaults.polyrhythmRhythm
        keepAwake = defaults.keepAwake
        sixteenthAlternate = defaults.sixteenthAlternate
        notificationsDeferredLocally = UserDefaults.standard.object(forKey: PreferenceKeys.remindersDeferredDate) != nil

        if sendReminders {
            checkPermissionsFromExternalTrigger()
        }

        defaults.onSendRemindersEnabled = { [weak self] in
            Task { @MainActor [weak self] in
                self?.checkPermissionsFromExternalTrigger()
            }
        }
    }

    private func requestPermissionAndSchedule() {
        Task { @MainActor in
            switch await notificationService.checkAndRequestAuthorization() {
            case .granted:
                clearDeferral()
                notificationsBlockedLocally = false
                notificationService.reschedule(at: reminderTime)
            case .denied:
                sendReminders = false
                showPermissionDeniedAlert = true
            case .notGranted:
                sendReminders = false
            }
        }
    }

    private func checkPermissionsFromExternalTrigger() {
        Task { @MainActor in
            switch await notificationService.currentAuthorizationStatus() {
            case .authorized, .provisional, .ephemeral:
                clearDeferral()
                notificationsBlockedLocally = false
                notificationService.reschedule(at: reminderTime)
            case .denied:
                notificationsBlockedLocally = true
            case .notDetermined:
                if notificationsDeferredLocally {
                    // Already deferred — keep inline warning visible, don't re-prompt
                    break
                }
                showCrossDeviceReminderPrompt = true
            @unknown default:
                notificationsBlockedLocally = true
            }
        }
    }

    func allowRemindersFromOtherDevice() {
        Task { @MainActor in
            switch await notificationService.checkAndRequestAuthorization() {
            case .granted:
                clearDeferral()
                notificationsBlockedLocally = false
                notificationService.reschedule(at: reminderTime)
            case .denied, .notGranted:
                // Deferral is resolved — permission is now actually denied
                clearDeferral()
                notificationsBlockedLocally = true
            }
        }
    }

    func declineRemindersFromOtherDevice() {
        UserDefaults.standard.set(
            Date.now.timeIntervalSinceReferenceDate,
            forKey: PreferenceKeys.remindersDeferredDate,
        )
        notificationsDeferredLocally = true
    }

    func refreshNotificationStatus() {
        guard sendReminders else { return }
        Task { @MainActor in
            switch await notificationService.currentAuthorizationStatus() {
            case .authorized, .provisional, .ephemeral:
                clearDeferral()
                notificationsBlockedLocally = false
                notificationService.reschedule(at: reminderTime)
            default:
                break
            }
        }
    }

    func openNotificationSettings() {
        #if targetEnvironment(macCatalyst)
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                UIApplication.shared.open(url)
            }
        #else
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        #endif
    }

    func rescheduleReminder(bodies: [String]) {
        guard sendReminders else { return }
        notificationService.schedule(bodies: bodies, at: reminderTime)
    }

    private func clearDeferral() {
        UserDefaults.standard.removeObject(forKey: PreferenceKeys.remindersDeferredDate)
        notificationsDeferredLocally = false
    }
}
