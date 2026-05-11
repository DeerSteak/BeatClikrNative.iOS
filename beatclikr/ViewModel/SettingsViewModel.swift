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

    @Published var metronomeBpm: Double {
        didSet { defaults.metronomeBpm = metronomeBpm }
    }

    @Published var metronomeGroove: Groove {
        didSet { defaults.metronomeGroove = metronomeGroove }
    }

    @Published var metronomeBeat: FileConstants {
        didSet { defaults.metronomeBeat = metronomeBeat }
    }

    @Published var metronomeRhythm: FileConstants {
        didSet { defaults.metronomeRhythm = metronomeRhythm }
    }

    @Published var metronomeBeatPattern: String? {
        didSet { defaults.metronomeBeatPattern = metronomeBeatPattern }
    }

    @Published var rampEnabled: Bool {
        didSet { defaults.rampEnabled = rampEnabled }
    }

    @Published var rampIncrement: Int {
        didSet { defaults.rampIncrement = rampIncrement }
    }

    @Published var rampInterval: Int {
        didSet { defaults.rampInterval = rampInterval }
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

    @Published var polyrhythmBeats: Int {
        didSet { defaults.polyrhythmBeats = polyrhythmBeats }
    }

    @Published var polyrhythmAgainst: Int {
        didSet { defaults.polyrhythmAgainst = polyrhythmAgainst }
    }

    @Published var polyrhythmBpm: Double {
        didSet { defaults.polyrhythmBpm = polyrhythmBpm }
    }

    @Published var keepAwake: Bool {
        didSet { defaults.keepAwake = keepAwake }
    }

    @Published var alwaysUseDarkTheme: Bool {
        didSet { defaults.alwaysUseDarkTheme = alwaysUseDarkTheme }
    }

    @Published var sixteenthAlternate: Bool {
        didSet { defaults.sixteenthAlternate = sixteenthAlternate }
    }

    @Published var playlistSortAscending: Bool {
        didSet { UserDefaults.standard.set(playlistSortAscending, forKey: PreferenceKeys.playlistSortAscending) }
    }

    init(notificationService: any ReminderNotificationServicing = ReminderNotificationService()) {
        self.notificationService = notificationService
        sendReminders = defaults.sendReminders
        reminderTime = defaults.reminderTime
        useFlashlight = defaults.useFlashlight
        useVibration = defaults.useVibration
        muteMetronome = defaults.muteMetronome
        metronomeBpm = defaults.metronomeBpm
        metronomeGroove = defaults.metronomeGroove
        metronomeBeat = defaults.metronomeBeat
        metronomeRhythm = defaults.metronomeRhythm
        metronomeBeatPattern = defaults.metronomeBeatPattern
        rampEnabled = defaults.rampEnabled
        rampIncrement = defaults.rampIncrement
        rampInterval = defaults.rampInterval
        playlistBeat = defaults.playlistBeat
        playlistRhythm = defaults.playlistRhythm
        polyrhythmBeat = defaults.polyrhythmBeat
        polyrhythmRhythm = defaults.polyrhythmRhythm
        polyrhythmBeats = defaults.polyrhythmBeats
        polyrhythmAgainst = defaults.polyrhythmAgainst
        polyrhythmBpm = defaults.polyrhythmBpm
        keepAwake = defaults.keepAwake
        alwaysUseDarkTheme = defaults.alwaysUseDarkTheme
        sixteenthAlternate = defaults.sixteenthAlternate
        playlistSortAscending = UserDefaults.standard.object(forKey: PreferenceKeys.playlistSortAscending) as? Bool ?? true
        notificationsDeferredLocally = UserDefaults.standard.object(forKey: PreferenceKeys.remindersDeferredDate) != nil

        if sendReminders {
            checkPermissionsFromExternalTrigger()
        }

        defaults.onSendRemindersEnabled = { [weak self] in
            Task { @MainActor [weak self] in
                self?.checkPermissionsFromExternalTrigger()
            }
        }
        defaults.onAlwaysUseDarkThemeChanged = { [weak self] newValue in
            Task { @MainActor [weak self] in
                self?.alwaysUseDarkTheme = newValue
            }
        }
    }

    func updateMetronomeBpm(_ bpm: Double) {
        metronomeBpm = bpm
    }

    func updateMetronomeGroove(_ groove: Groove) {
        metronomeGroove = groove
    }

    func updateMetronomeBeat(_ beat: FileConstants) {
        metronomeBeat = beat
    }

    func updateMetronomeRhythm(_ rhythm: FileConstants) {
        metronomeRhythm = rhythm
    }

    func updateMetronomeBeatPattern(_ beatPattern: BeatPattern?) {
        metronomeBeatPattern = beatPattern?.rawValue
    }

    func updateRampEnabled(_ enabled: Bool) {
        rampEnabled = enabled
    }

    func updateRampIncrement(_ increment: Int) {
        rampIncrement = increment
    }

    func updateRampInterval(_ interval: Int) {
        rampInterval = interval
    }

    func updatePlaylistBeat(_ beat: FileConstants) {
        playlistBeat = beat
    }

    func updatePlaylistRhythm(_ rhythm: FileConstants) {
        playlistRhythm = rhythm
    }

    func updatePolyrhythmBeats(_ beats: Int) {
        polyrhythmBeats = beats
    }

    func updatePolyrhythmAgainst(_ against: Int) {
        polyrhythmAgainst = against
    }

    func updatePolyrhythmBpm(_ bpm: Double) {
        polyrhythmBpm = bpm
    }

    func updatePolyrhythmBeat(_ beat: FileConstants) {
        polyrhythmBeat = beat
    }

    func updatePolyrhythmRhythm(_ rhythm: FileConstants) {
        polyrhythmRhythm = rhythm
    }

    func updatePlaylistSortAscending(_ ascending: Bool) {
        playlistSortAscending = ascending
    }

    static func configureUITestNotificationState(_ state: String?) {
        UserDefaults.standard.removeObject(forKey: PreferenceKeys.remindersDeferredDate)
        UserDefaults.standard.set(false, forKey: PreferenceKeys.sendReminders)
        if state == "deferred" {
            UserDefaults.standard.set(
                Date.now.timeIntervalSinceReferenceDate,
                forKey: PreferenceKeys.remindersDeferredDate,
            )
            UserDefaults.standard.set(true, forKey: PreferenceKeys.sendReminders)
        }
    }

    static func configureUITestMetronomeReset() {
        UserDefaults.standard.set(false, forKey: PreferenceKeys.rampEnabled)
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
