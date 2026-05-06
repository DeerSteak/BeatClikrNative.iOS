//
//  UserDefaultsService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/6/23.
//

import Foundation
import AVFoundation

@MainActor
class UserDefaultsService: ObservableObject {
    
    // MARK: - General settings
    
    @Published var keepAwake: Bool {
        didSet { syncSave(keepAwake, oldValue: oldValue, key: PreferenceKeys.keepAwake) }
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
    
    // Called when sendReminders changed from false -> true via cloud sync.
    var onSendRemindersEnabled: (() -> Void)?
    
    // MARK: - Instant metronome
    
    @Published var instantBeat: FileConstants {
        didSet { syncSave(instantBeat, oldValue: oldValue, key: PreferenceKeys.instantBeat) }
    }
    
    @Published var instantBeatPattern: String? {
        didSet { syncSave(instantBeatPattern, oldValue: oldValue, key: PreferenceKeys.instantBeatPattern) }
    }
    
    @Published var instantBpm: Double {
        didSet { syncSave(instantBpm, oldValue: oldValue, key: PreferenceKeys.instantBpm) }
    }
    
    @Published var instantGroove: Groove {
        didSet { syncSave(instantGroove, oldValue: oldValue, key: PreferenceKeys.instantGroove) }
    }
    
    @Published var instantRhythm: FileConstants {
        didSet { syncSave(instantRhythm, oldValue: oldValue, key: PreferenceKeys.instantRhythm) }
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
    
    private let defaults = UserDefaults.standard
    private let cloud = NSUbiquitousKeyValueStore.default
    
    static let instance = UserDefaultsService()
    
    init() {
        useFlashlight = defaults.bool(forKey: PreferenceKeys.useFlashlight)
        useVibration = defaults.bool(forKey: PreferenceKeys.useHaptic)
        muteMetronome = defaults.bool(forKey: PreferenceKeys.muteMetronome)
        keepAwake = defaults.bool(forKey: PreferenceKeys.keepAwake)
        sixteenthAlternate = defaults.bool(forKey: PreferenceKeys.sixteenthAlternate)
        
        instantBeat = Self.loadEnum(defaults, key: PreferenceKeys.instantBeat, default: .ClickHi)
        instantRhythm = Self.loadEnum(defaults, key: PreferenceKeys.instantRhythm, default: .ClickLo)
        instantBpm = Self.loadNonZeroDouble(defaults, key: PreferenceKeys.instantBpm, default: 60)
        instantGroove = Self.loadEnum(defaults, key: PreferenceKeys.instantGroove, default: .quarter)
        instantBeatPattern = Self.loadOptionalString(defaults, key: PreferenceKeys.instantBeatPattern)
        
        playlistBeat = Self.loadEnum(defaults, key: PreferenceKeys.playlistBeat, default: .ClickHi)
        playlistRhythm = Self.loadEnum(defaults, key: PreferenceKeys.playlistRhythm, default: .ClickLo)
        
        polyrhythmBeat = Self.loadEnum(defaults, key: PreferenceKeys.polyrhythmBeat, default: .ClickHi)
        polyrhythmRhythm = Self.loadEnum(defaults, key: PreferenceKeys.polyrhythmRhythm, default: .ClickLo)
        polyrhythmBeats = Self.loadNonZeroInt(defaults, key: PreferenceKeys.polyrhythmBeats, default: 3)
        polyrhythmAgainst = Self.loadNonZeroInt(defaults, key: PreferenceKeys.polyrhythmAgainst, default: 2)
        
        sendReminders = defaults.bool(forKey: PreferenceKeys.sendReminders)
        reminderTime = Self.loadNonZeroDate(defaults, key: PreferenceKeys.reminderTime, default: .now)
        
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud,
            queue: .main
        ) { [weak self] _ in
            Swift.Task { @MainActor in
                self?.syncWithCloud()
            }
        }
        
        cloud.synchronize()
    }
    
    // Ensure this is a private Swift function (No @objc)
    private func syncWithCloud() {
        cloud.synchronize()
        
        // Explicit 'self' prevents namespace collisions with Swift types like 'Bool'
        self.useFlashlight = cloud.bool(forKey: PreferenceKeys.useFlashlight)
        self.useVibration = cloud.bool(forKey: PreferenceKeys.useHaptic)
        self.muteMetronome = cloud.bool(forKey: PreferenceKeys.muteMetronome)
        self.keepAwake = cloud.bool(forKey: PreferenceKeys.keepAwake)
        self.sixteenthAlternate = cloud.bool(forKey: PreferenceKeys.sixteenthAlternate)
        
        self.instantBeat = cloudEnum(PreferenceKeys.instantBeat, default: .ClickHi)
        self.instantRhythm = cloudEnum(PreferenceKeys.instantRhythm, default: .ClickLo)
        self.instantBpm = cloudNonZeroDouble(PreferenceKeys.instantBpm, default: 60)
        self.instantGroove = cloudEnum(PreferenceKeys.instantGroove, default: .quarter)
        self.instantBeatPattern = cloudOptionalString(PreferenceKeys.instantBeatPattern)
        
        self.playlistBeat = cloudEnum(PreferenceKeys.playlistBeat, default: .ClickHi)
        self.playlistRhythm = cloudEnum(PreferenceKeys.playlistRhythm, default: .ClickLo)
        
        self.polyrhythmBeat = cloudEnum(PreferenceKeys.polyrhythmBeat, default: .ClickHi)
        self.polyrhythmRhythm = cloudEnum(PreferenceKeys.polyrhythmRhythm, default: .ClickLo)
        self.polyrhythmBeats = cloudNonZeroInt(PreferenceKeys.polyrhythmBeats, default: 3)
        self.polyrhythmAgainst = cloudNonZeroInt(PreferenceKeys.polyrhythmAgainst, default: 2)
        
        let wasSendingReminders = self.sendReminders
        self.sendReminders = cloud.bool(forKey: PreferenceKeys.sendReminders)
        if !wasSendingReminders && self.sendReminders {
            onSendRemindersEnabled?()
        }
        
        let cloudInterval = cloud.double(forKey: PreferenceKeys.reminderTime)
        if cloudInterval != 0 {
            self.reminderTime = Date(timeIntervalSinceReferenceDate: cloudInterval)
        }
    }
    
    // MARK: - didSet sync helpers
    
    private func syncSave<T: Equatable & RawRepresentable>(_ newValue: T, oldValue: T, key: String) where T.RawValue == String {
        guard oldValue != newValue else { return }
        defaults.setValue(newValue.rawValue, forKey: key)
        cloud.set(newValue.rawValue, forKey: key)
    }
    
    private func syncSave<T: Equatable & RawRepresentable>(_ newValue: T, oldValue: T, key: String) where T.RawValue == Int {
        guard oldValue != newValue else { return }
        defaults.setValue(newValue.rawValue, forKey: key)
        cloud.set(Int64(newValue.rawValue), forKey: key)
    }
    
    private func syncSave(_ newValue: Bool, oldValue: Bool, key: String) {
        guard oldValue != newValue else { return }
        defaults.setValue(newValue, forKey: key)
        cloud.set(newValue, forKey: key)
    }
    
    private func syncSave(_ newValue: Double, oldValue: Double, key: String) {
        guard oldValue != newValue else { return }
        defaults.setValue(newValue, forKey: key)
        cloud.set(newValue, forKey: key)
    }
    
    private func syncSave(_ newValue: Int, oldValue: Int, key: String) {
        guard oldValue != newValue else { return }
        defaults.setValue(newValue, forKey: key)
        cloud.set(Int64(newValue), forKey: key)
    }
    
    private func syncSave(_ newValue: String?, oldValue: String?, key: String) {
        guard oldValue != newValue else { return }
        defaults.setValue(newValue ?? "", forKey: key)
        cloud.set(newValue ?? "", forKey: key)
    }
    
    private func syncSave(_ newValue: Date, oldValue: Date, key: String) {
        guard oldValue != newValue else { return }
        defaults.set(newValue.timeIntervalSinceReferenceDate, forKey: key)
        cloud.set(newValue.timeIntervalSinceReferenceDate, forKey: key)
    }
    
    // MARK: - Static load helpers (for init, before self is fully initialized)
    
    private static func loadEnum<T: RawRepresentable>(_ defaults: UserDefaults, key: String, default fallback: T) -> T where T.RawValue == String {
        T(rawValue: defaults.string(forKey: key) ?? "") ?? fallback
    }
    
    private static func loadEnum<T: RawRepresentable>(_ defaults: UserDefaults, key: String, default fallback: T) -> T where T.RawValue == Int {
        T(rawValue: defaults.integer(forKey: key)) ?? fallback
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
