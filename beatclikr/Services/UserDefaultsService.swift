//
//  UserDefaultsService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/6/23.
//

import AVFoundation
import Foundation

@MainActor
class UserDefaultsService: ObservableObject {
    // MARK: - General settings

    @Published var keepAwake: Bool {
        didSet { syncSave(keepAwake, oldValue: oldValue, key: PreferenceKeys.keepAwake) }
    }

    @Published var alwaysUseDarkTheme: Bool {
        didSet { syncSave(alwaysUseDarkTheme, oldValue: oldValue, key: PreferenceKeys.alwaysUseDarkTheme) }
    }

    @Published var muteMetronome: Bool {
        didSet { syncSave(muteMetronome, oldValue: oldValue, key: PreferenceKeys.muteMetronome) }
    }

    @Published var sixteenthAlternate: Bool {
        didSet { syncSave(sixteenthAlternate, oldValue: oldValue, key: PreferenceKeys.sixteenthAlternate) }
    }

    @Published var useFlashlight: Bool {
        didSet { syncSave(useFlashlight, oldValue: oldValue, key: PreferenceKeys.useFlashlight) }
    }

    @Published var useVibration: Bool {
        didSet { syncSave(useVibration, oldValue: oldValue, key: PreferenceKeys.useHaptic) }
    }

    // MARK: - Reminders

    @Published var sendReminders: Bool {
        didSet { syncSave(sendReminders, oldValue: oldValue, key: PreferenceKeys.sendReminders) }
    }

    @Published var reminderTime: Date {
        didSet { syncSave(reminderTime, oldValue: oldValue, key: PreferenceKeys.reminderTime) }
    }

    /// Called when sendReminders changed from false -> true via cloud sync.
    var onSendRemindersEnabled: (() -> Void)?
    var onAlwaysUseDarkThemeChanged: ((Bool) -> Void)?

    // MARK: - Metronome

    @Published var metronomeBeat: FileConstants {
        didSet { syncSave(metronomeBeat, oldValue: oldValue, key: PreferenceKeys.metronomeBeat) }
    }

    @Published var metronomeBeatPattern: String? {
        didSet { syncSave(metronomeBeatPattern, oldValue: oldValue, key: PreferenceKeys.metronomeBeatPattern) }
    }

    @Published var metronomeBpm: Double {
        didSet { syncSave(metronomeBpm, oldValue: oldValue, key: PreferenceKeys.metronomeBpm) }
    }

    @Published var metronomeGroove: Groove {
        didSet { syncSave(metronomeGroove, oldValue: oldValue, key: PreferenceKeys.metronomeGroove) }
    }

    @Published var metronomeRhythm: FileConstants {
        didSet { syncSave(metronomeRhythm, oldValue: oldValue, key: PreferenceKeys.metronomeRhythm) }
    }

    @Published var rampEnabled: Bool {
        didSet { syncSave(rampEnabled, oldValue: oldValue, key: PreferenceKeys.rampEnabled) }
    }

    @Published var rampIncrement: Int {
        didSet { syncSave(rampIncrement, oldValue: oldValue, key: PreferenceKeys.rampIncrement) }
    }

    @Published var rampInterval: Int {
        didSet { syncSave(rampInterval, oldValue: oldValue, key: PreferenceKeys.rampInterval) }
    }

    // MARK: - Playlist

    @Published var playlistBeat: FileConstants {
        didSet { syncSave(playlistBeat, oldValue: oldValue, key: PreferenceKeys.playlistBeat) }
    }

    @Published var playlistRhythm: FileConstants {
        didSet { syncSave(playlistRhythm, oldValue: oldValue, key: PreferenceKeys.playlistRhythm) }
    }

    // MARK: - Polyrhythm

    @Published var polyrhythmAgainst: Int {
        didSet { syncSave(polyrhythmAgainst, oldValue: oldValue, key: PreferenceKeys.polyrhythmAgainst) }
    }

    @Published var polyrhythmBeat: FileConstants {
        didSet { syncSave(polyrhythmBeat, oldValue: oldValue, key: PreferenceKeys.polyrhythmBeat) }
    }

    @Published var polyrhythmBeats: Int {
        didSet { syncSave(polyrhythmBeats, oldValue: oldValue, key: PreferenceKeys.polyrhythmBeats) }
    }

    @Published var polyrhythmRhythm: FileConstants {
        didSet { syncSave(polyrhythmRhythm, oldValue: oldValue, key: PreferenceKeys.polyrhythmRhythm) }
    }

    @Published var polyrhythmBpm: Double {
        didSet { syncSave(polyrhythmBpm, oldValue: oldValue, key: PreferenceKeys.polyrhythmBpm) }
    }

    private let defaults = UserDefaults.standard
    private let cloud = NSUbiquitousKeyValueStore.default
    private var isSyncingFromCloud = false

    static let instance = UserDefaultsService()

    init() {
        useFlashlight = defaults.bool(forKey: PreferenceKeys.useFlashlight)
        useVibration = defaults.bool(forKey: PreferenceKeys.useHaptic)
        muteMetronome = defaults.bool(forKey: PreferenceKeys.muteMetronome)
        keepAwake = defaults.bool(forKey: PreferenceKeys.keepAwake)
        alwaysUseDarkTheme = Self.loadBool(defaults, key: PreferenceKeys.alwaysUseDarkTheme, default: true)
        sixteenthAlternate = defaults.bool(forKey: PreferenceKeys.sixteenthAlternate)

        metronomeBeat = Self.loadEnum(defaults, key: PreferenceKeys.metronomeBeat, default: .ClickHi)
        metronomeRhythm = Self.loadEnum(defaults, key: PreferenceKeys.metronomeRhythm, default: .ClickLo)
        metronomeBpm = Self.loadNonZeroDouble(defaults, key: PreferenceKeys.metronomeBpm, default: 60)
        metronomeGroove = Self.loadEnum(defaults, key: PreferenceKeys.metronomeGroove, default: .quarter)
        metronomeBeatPattern = Self.loadOptionalString(defaults, key: PreferenceKeys.metronomeBeatPattern)

        rampEnabled = defaults.bool(forKey: PreferenceKeys.rampEnabled)
        rampIncrement = Self.loadNonZeroInt(defaults, key: PreferenceKeys.rampIncrement, default: 2)
        rampInterval = Self.loadNonZeroInt(defaults, key: PreferenceKeys.rampInterval, default: 8)

        playlistBeat = Self.loadEnum(defaults, key: PreferenceKeys.playlistBeat, default: .ClickHi)
        playlistRhythm = Self.loadEnum(defaults, key: PreferenceKeys.playlistRhythm, default: .ClickLo)

        polyrhythmBeat = Self.loadEnum(defaults, key: PreferenceKeys.polyrhythmBeat, default: .ClickHi)
        polyrhythmRhythm = Self.loadEnum(defaults, key: PreferenceKeys.polyrhythmRhythm, default: .ClickLo)
        polyrhythmBeats = Self.loadNonZeroInt(defaults, key: PreferenceKeys.polyrhythmBeats, default: 3)
        polyrhythmAgainst = Self.loadNonZeroInt(defaults, key: PreferenceKeys.polyrhythmAgainst, default: 2)
        polyrhythmBpm = Self.loadNonZeroDouble(defaults, key: PreferenceKeys.polyrhythmBpm, default: 60)

        sendReminders = defaults.bool(forKey: PreferenceKeys.sendReminders)
        reminderTime = Self.loadNonZeroDate(defaults, key: PreferenceKeys.reminderTime, default: .now)

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud,
            queue: .main,
        ) { [weak self] _ in
            Swift.Task { @MainActor in
                self?.syncWithCloud()
            }
        }

        cloud.synchronize()
    }

    /// Ensure this is a private Swift function (No @objc)
    private func syncWithCloud() {
        cloud.synchronize()
        isSyncingFromCloud = true
        var didEnableRemindersFromCloud = false
        var didChangeAlwaysUseDarkTheme = false
        defer {
            isSyncingFromCloud = false
            if didChangeAlwaysUseDarkTheme {
                onAlwaysUseDarkThemeChanged?(alwaysUseDarkTheme)
            }
            if didEnableRemindersFromCloud {
                onSendRemindersEnabled?()
            }
        }

        // Explicit 'self' prevents namespace collisions with Swift types like 'Bool'
        useFlashlight = cloud.bool(forKey: PreferenceKeys.useFlashlight)
        useVibration = cloud.bool(forKey: PreferenceKeys.useHaptic)
        muteMetronome = cloud.bool(forKey: PreferenceKeys.muteMetronome)
        let oldAlwaysUseDarkTheme = alwaysUseDarkTheme
        keepAwake = cloud.bool(forKey: PreferenceKeys.keepAwake)
        if cloud.object(forKey: PreferenceKeys.alwaysUseDarkTheme) != nil {
            alwaysUseDarkTheme = cloud.bool(forKey: PreferenceKeys.alwaysUseDarkTheme)
        }
        if oldAlwaysUseDarkTheme != alwaysUseDarkTheme {
            didChangeAlwaysUseDarkTheme = true
        }
        sixteenthAlternate = cloud.bool(forKey: PreferenceKeys.sixteenthAlternate)

        metronomeBeat = cloudEnum(PreferenceKeys.metronomeBeat, default: .ClickHi)
        metronomeRhythm = cloudEnum(PreferenceKeys.metronomeRhythm, default: .ClickLo)
        metronomeBpm = cloudNonZeroDouble(PreferenceKeys.metronomeBpm, default: 60)
        metronomeGroove = cloudEnum(PreferenceKeys.metronomeGroove, default: .quarter)
        metronomeBeatPattern = cloudOptionalString(PreferenceKeys.metronomeBeatPattern)

        rampEnabled = cloud.bool(forKey: PreferenceKeys.rampEnabled)
        rampIncrement = cloudNonZeroInt(PreferenceKeys.rampIncrement, default: 2)
        rampInterval = cloudNonZeroInt(PreferenceKeys.rampInterval, default: 8)

        playlistBeat = cloudEnum(PreferenceKeys.playlistBeat, default: .ClickHi)
        playlistRhythm = cloudEnum(PreferenceKeys.playlistRhythm, default: .ClickLo)

        polyrhythmBeat = cloudEnum(PreferenceKeys.polyrhythmBeat, default: .ClickHi)
        polyrhythmRhythm = cloudEnum(PreferenceKeys.polyrhythmRhythm, default: .ClickLo)
        polyrhythmBeats = cloudNonZeroInt(PreferenceKeys.polyrhythmBeats, default: 3)
        polyrhythmAgainst = cloudNonZeroInt(PreferenceKeys.polyrhythmAgainst, default: 2)
        polyrhythmBpm = cloudNonZeroDouble(PreferenceKeys.polyrhythmBpm, default: 60)

        let wasSendingReminders = sendReminders
        sendReminders = cloud.bool(forKey: PreferenceKeys.sendReminders)
        if !wasSendingReminders, sendReminders {
            didEnableRemindersFromCloud = true
        }

        let cloudInterval = cloud.double(forKey: PreferenceKeys.reminderTime)
        if cloudInterval != 0 {
            reminderTime = Date(timeIntervalSinceReferenceDate: cloudInterval)
        }
    }

    // MARK: - didSet sync helpers

    private func syncSave<T: Equatable & RawRepresentable>(_ newValue: T, oldValue: T, key: String) where T.RawValue == String {
        guard oldValue != newValue else { return }
        defaults.setValue(newValue.rawValue, forKey: key)
        guard !isSyncingFromCloud else { return }
        cloud.set(newValue.rawValue, forKey: key)
    }

    private func syncSave<T: Equatable & RawRepresentable>(_ newValue: T, oldValue: T, key: String) where T.RawValue == Int {
        guard oldValue != newValue else { return }
        defaults.setValue(newValue.rawValue, forKey: key)
        guard !isSyncingFromCloud else { return }
        cloud.set(Int64(newValue.rawValue), forKey: key)
    }

    private func syncSave(_ newValue: Bool, oldValue: Bool, key: String) {
        guard oldValue != newValue else { return }
        defaults.setValue(newValue, forKey: key)
        guard !isSyncingFromCloud else { return }
        cloud.set(newValue, forKey: key)
    }

    private func syncSave(_ newValue: Double, oldValue: Double, key: String) {
        guard oldValue != newValue else { return }
        defaults.setValue(newValue, forKey: key)
        guard !isSyncingFromCloud else { return }
        cloud.set(newValue, forKey: key)
    }

    private func syncSave(_ newValue: Int, oldValue: Int, key: String) {
        guard oldValue != newValue else { return }
        defaults.setValue(newValue, forKey: key)
        guard !isSyncingFromCloud else { return }
        cloud.set(Int64(newValue), forKey: key)
    }

    private func syncSave(_ newValue: String?, oldValue: String?, key: String) {
        guard oldValue != newValue else { return }
        defaults.setValue(newValue ?? "", forKey: key)
        guard !isSyncingFromCloud else { return }
        cloud.set(newValue ?? "", forKey: key)
    }

    private func syncSave(_ newValue: Date, oldValue: Date, key: String) {
        guard oldValue != newValue else { return }
        defaults.set(newValue.timeIntervalSinceReferenceDate, forKey: key)
        guard !isSyncingFromCloud else { return }
        cloud.set(newValue.timeIntervalSinceReferenceDate, forKey: key)
    }

    // MARK: - Static load helpers (for init, before self is fully initialized)

    private static func loadEnum<T: RawRepresentable>(_ defaults: UserDefaults, key: String, default fallback: T) -> T where T.RawValue == String {
        T(rawValue: defaults.string(forKey: key) ?? "") ?? fallback
    }

    private static func loadEnum<T: RawRepresentable>(_ defaults: UserDefaults, key: String, default fallback: T) -> T where T.RawValue == Int {
        T(rawValue: defaults.integer(forKey: key)) ?? fallback
    }

    private static func loadBool(_ defaults: UserDefaults, key: String, default fallback: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
    }

    private static func loadNonZeroDouble(_ defaults: UserDefaults, key: String, default fallback: Double) -> Double {
        let v = defaults.double(forKey: key)
        return v == 0 ? fallback : v
    }

    private static func loadNonZeroInt(_ defaults: UserDefaults, key: String, default fallback: Int) -> Int {
        let v = defaults.integer(forKey: key)
        return v == 0 ? fallback : v
    }

    private static func loadOptionalString(_ defaults: UserDefaults, key: String) -> String? {
        let s = defaults.string(forKey: key) ?? ""
        return s.isEmpty ? nil : s
    }

    private static func loadNonZeroDate(_ defaults: UserDefaults, key: String, default fallback: Date) -> Date {
        let v = defaults.double(forKey: key)
        return v == 0 ? fallback : Date(timeIntervalSinceReferenceDate: v)
    }

    // MARK: - Cloud load helpers (for syncWithCloud)

    private func cloudEnum<T: RawRepresentable>(_ key: String, default fallback: T) -> T where T.RawValue == String {
        T(rawValue: cloud.string(forKey: key) ?? "") ?? fallback
    }

    private func cloudEnum<T: RawRepresentable>(_ key: String, default fallback: T) -> T where T.RawValue == Int {
        T(rawValue: Int(cloud.longLong(forKey: key))) ?? fallback
    }

    private func cloudNonZeroDouble(_ key: String, default fallback: Double) -> Double {
        let v = cloud.double(forKey: key)
        return v == 0 ? fallback : v
    }

    private func cloudNonZeroInt(_ key: String, default fallback: Int) -> Int {
        let v = Int(cloud.longLong(forKey: key))
        return v == 0 ? fallback : v
    }

    private func cloudOptionalString(_ key: String) -> String? {
        let s = cloud.string(forKey: key) ?? ""
        return s.isEmpty ? nil : s
    }
}
