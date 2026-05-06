//
//  beatclikrApp.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import CoreData
import SwiftData
import SwiftUI

@main
@MainActor
struct beatclikrApp: App {
    @Environment(\.scenePhase) private var scenePhase

    let container: ModelContainer

    @StateObject private var metronomeViewModel: MetronomePlaybackViewModel
    @StateObject private var polyrhythmViewModel: PolyrhythmViewModel
    @StateObject private var songLibraryViewModel: SongLibraryViewModel
    @StateObject private var playlistListViewModel: PlaylistListViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var practiceHistoryViewModel: PracticeHistoryViewModel

    private static let uiTestPracticeState: String? =
        ProcessInfo.processInfo.environment["UI_TESTING_PRACTICE_STATE"]
    private static let uiTestNotificationState: String? =
        ProcessInfo.processInfo.environment["UI_TESTING_NOTIFICATION_STATE"]

    init() {
        let isUITesting = Self.uiTestPracticeState != nil
        let config: ModelConfiguration = isUITesting
            ? ModelConfiguration(isStoredInMemoryOnly: true)
            : ModelConfiguration(cloudKitDatabase: .private("iCloud.com.bfunkstudios.beatclikr"))

        do {
            container = try ModelContainer(
                for: Song.self,
                PlaylistEntry.self,
                Playlist.self,
                PracticedSong.self,
                PracticeSession.self,
                configurations: config
            )
        } catch {
            fatalError(error.localizedDescription)
        }

        let context = container.mainContext

        if let state = Self.uiTestPracticeState {
            // Reset notification-related defaults to a known clean baseline for each UI test
            UserDefaults.standard.removeObject(forKey: PreferenceKeys.remindersDeferredDate)
            UserDefaults.standard.set(false, forKey: PreferenceKeys.sendReminders)
            if Self.uiTestNotificationState == "deferred" {
                UserDefaults.standard.set(
                    Date.now.timeIntervalSinceReferenceDate,
                    forKey: PreferenceKeys.remindersDeferredDate
                )
                UserDefaults.standard.set(true, forKey: PreferenceKeys.sendReminders)
            }
            Self.seedUITestData(state: state, context: context)
        } else {
            // Remove entries whose song was deleted
            let orphaned = (try? context.fetch(
                FetchDescriptor<PlaylistEntry>(predicate: #Predicate { $0.song == nil })
            )) ?? []
            if !orphaned.isEmpty {
                orphaned.forEach { context.delete($0) }
                try? context.save()
            }

            // Migrate legacy entries (no playlist) into a default playlist (once per device)
            if !UserDefaults.standard.bool(forKey: PreferenceKeys.didMigrateToMultiplePlaylists) {
                let legacyEntries = (try? context.fetch(
                    FetchDescriptor<PlaylistEntry>(predicate: #Predicate { $0.playlist == nil })
                )) ?? []
                if !legacyEntries.isEmpty {
                    let existing = (try? context.fetch(
                        FetchDescriptor<Playlist>(predicate: #Predicate { $0.name == "My Playlist" })
                    ))?.first
                    let defaultPlaylist = existing ?? {
                        let p = Playlist(name: "My Playlist")
                        context.insert(p)
                        return p
                    }()
                    for entry in legacyEntries {
                        entry.playlist = defaultPlaylist
                    }
                    try? context.save()
                }
                UserDefaults.standard.set(true, forKey: PreferenceKeys.didMigrateToMultiplePlaylists)
            }
        }

        let metronome = MetronomePlaybackViewModel()
        _metronomeViewModel = StateObject(wrappedValue: metronome)
        _polyrhythmViewModel = StateObject(wrappedValue: PolyrhythmViewModel())
        _songLibraryViewModel = StateObject(wrappedValue: SongLibraryViewModel())
        _playlistListViewModel = StateObject(wrappedValue: PlaylistListViewModel())
        let settingsVM = SettingsViewModel()
        let practiceVM = PracticeHistoryViewModel()
        practiceVM.onPracticeRecorded = { [weak practiceVM, weak settingsVM] context in
            guard let vm = practiceVM, let settings = settingsVM else { return }
            let dates = vm.markedDates(context: context)
            let bodies = vm.scheduledNotificationBodies(from: dates, days: 7)
            settings.rescheduleReminder(bodies: bodies)
        }
        _settingsViewModel = StateObject(wrappedValue: settingsVM)
        _practiceHistoryViewModel = StateObject(wrappedValue: practiceVM)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(songLibraryViewModel)
                .environmentObject(playlistListViewModel)
                .environmentObject(metronomeViewModel)
                .environmentObject(polyrhythmViewModel)
                .environmentObject(settingsViewModel)
                .environmentObject(practiceHistoryViewModel)
                .onReceive(
                    NotificationCenter.default
                        .publisher(for: .NSPersistentStoreRemoteChange)
                        .receive(on: DispatchQueue.main)
                ) { _ in
                    guard settingsViewModel.sendReminders else { return }
                    let dates = practiceHistoryViewModel.markedDates(context: container.mainContext)
                    let bodies = practiceHistoryViewModel.scheduledNotificationBodies(from: dates, days: 7)
                    settingsViewModel.rescheduleReminder(bodies: bodies)
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            let dates = practiceHistoryViewModel.markedDates(context: container.mainContext)
            let bodies = practiceHistoryViewModel.scheduledNotificationBodies(from: dates, days: 7)
            settingsViewModel.rescheduleReminder(bodies: bodies)
            settingsViewModel.refreshNotificationStatus()
        }
    }

    private static func seedUITestData(state: String, context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        switch state {
        case "streak_yesterday":
            context.insert(PracticeSession(date: cal.date(byAdding: .day, value: -1, to: today)!))
        case "streak_active":
            context.insert(PracticeSession(date: today))
            context.insert(PracticeSession(date: cal.date(byAdding: .day, value: -1, to: today)!))
        case "streak_5_days":
            for i in 0 ..< 5 {
                context.insert(PracticeSession(date: cal.date(byAdding: .day, value: -i, to: today)!))
            }
        default:
            break
        }
        try? context.save()
    }
}
