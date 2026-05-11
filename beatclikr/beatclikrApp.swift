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

    @State private var container: ModelContainer
    @State private var databaseRecoveryAlert: DatabaseRecoveryAlert?
    @State private var showTemporaryStoreNotice = false

    @StateObject private var defaults = UserDefaultsService.instance
    @State private var selectedSection: AppSection? = .metronome
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
    private static let uiTestMetronomeReset: Bool =
        ProcessInfo.processInfo.environment["UI_TESTING_METRONOME_RESET"] != nil

    init() {
        let isUITesting = Self.uiTestPracticeState != nil
        let startup = Self.makeStartupContainer(isUITesting: isUITesting)
        _container = State(initialValue: startup.container)
        _databaseRecoveryAlert = State(initialValue: startup.recoveryAlert)

        let context = startup.container.mainContext

        if let state = Self.uiTestPracticeState {
            SettingsViewModel.configureUITestNotificationState(Self.uiTestNotificationState)
            Self.seedUITestData(state: state, context: context)
        } else if startup.recoveryAlert == nil {
            Self.performStartupMaintenance(context: context)
        }

        if Self.uiTestMetronomeReset {
            SettingsViewModel.configureUITestMetronomeReset()
        }

        let settingsVM = SettingsViewModel()
        let metronome = MetronomePlaybackViewModel(settings: settingsVM)
        _metronomeViewModel = StateObject(wrappedValue: metronome)
        _polyrhythmViewModel = StateObject(wrappedValue: PolyrhythmViewModel(settings: settingsVM))
        _songLibraryViewModel = StateObject(wrappedValue: SongLibraryViewModel())
        _playlistListViewModel = StateObject(wrappedValue: PlaylistListViewModel())
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
            appContent
                .preferredColorScheme(defaults.alwaysUseDarkTheme ? .dark : nil)
                .transaction { transaction in
                    transaction.disablesAnimations = true
                }
                .onAppear {
                    updateIdleTimer(for: scenePhase)
                }
                .alert(item: $databaseRecoveryAlert) { alert in
                    Alert(
                        title: Text("Database Needs Attention"),
                        message: Text(alert.message),
                        primaryButton: .destructive(Text("Reset Local Database")) {
                            resetPersistentDatabase()
                        },
                        secondaryButton: .cancel(Text("Use Temporary Store")) {
                            showTemporaryStoreNotice = true
                        },
                    )
                }
                .alert("Temporary Store Active", isPresented: $showTemporaryStoreNotice) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Changes you make on this device will not be preserved until BeatClikr can reopen a local database. Your synced data may still be recoverable from another device.")
                }
                .onChange(of: defaults.keepAwake) { _, _ in
                    updateIdleTimer(for: scenePhase)
                }
                .onReceive(
                    NotificationCenter.default
                        .publisher(for: .NSPersistentStoreRemoteChange)
                        .receive(on: DispatchQueue.main),
                ) { _ in
                    guard settingsViewModel.sendReminders else { return }
                    let dates = practiceHistoryViewModel.markedDates(context: container.mainContext)
                    let bodies = practiceHistoryViewModel.scheduledNotificationBodies(from: dates, days: 7)
                    settingsViewModel.rescheduleReminder(bodies: bodies)
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                updateIdleTimer(for: newPhase)
                return
            }
            updateIdleTimer(for: newPhase)
            let dates = practiceHistoryViewModel.markedDates(context: container.mainContext)
            let bodies = practiceHistoryViewModel.scheduledNotificationBodies(from: dates, days: 7)
            settingsViewModel.rescheduleReminder(bodies: bodies)
            settingsViewModel.refreshNotificationStatus()
        }
    }

    private var appContent: some View {
        HomeView(selectedSection: $selectedSection)
            .environmentObject(songLibraryViewModel)
            .environmentObject(playlistListViewModel)
            .environmentObject(metronomeViewModel)
            .environmentObject(polyrhythmViewModel)
            .environmentObject(settingsViewModel)
            .environmentObject(practiceHistoryViewModel)
    }

    private func updateIdleTimer(for phase: ScenePhase) {
        UIApplication.shared.isIdleTimerDisabled = phase == .active && defaults.keepAwake
    }

    private func resetPersistentDatabase() {
        do {
            try Self.deletePersistentStoreFiles()
            let newContainer = try Self.makePersistentContainer()
            Self.performStartupMaintenance(context: newContainer.mainContext)
            container = newContainer
            databaseRecoveryAlert = nil
        } catch {
            databaseRecoveryAlert = nil
            showTemporaryStoreNotice = true
        }
    }

    private static func makeStartupContainer(isUITesting: Bool) -> (container: ModelContainer, recoveryAlert: DatabaseRecoveryAlert?) {
        do {
            let container = try isUITesting ? makeInMemoryContainer() : makePersistentContainer()
            return (container, nil)
        } catch {
            do {
                let container = try makeInMemoryContainer()
                return (container, DatabaseRecoveryAlert(error: error))
            } catch {
                preconditionFailure("BeatClikr could not create either a persistent or temporary database: \(error)")
            }
        }
    }

    private static func makePersistentContainer() throws -> ModelContainer {
        let config = ModelConfiguration(cloudKitDatabase: .private("iCloud.com.bfunkstudios.beatclikr"))
        return try makeContainer(config: config)
    }

    private static func makeInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try makeContainer(config: config)
    }

    private static func makeContainer(config: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(
            for: Song.self,
            PlaylistEntry.self,
            Playlist.self,
            PracticedSong.self,
            PracticeSession.self,
            configurations: config,
        )
    }

    private static func performStartupMaintenance(context: ModelContext) {
        let orphaned = (try? context.fetch(
            FetchDescriptor<PlaylistEntry>(predicate: #Predicate { $0.song == nil }),
        )) ?? []
        if !orphaned.isEmpty {
            orphaned.forEach { context.delete($0) }
            try? context.save()
        }

        guard !UserDefaults.standard.bool(forKey: PreferenceKeys.didMigrateToMultiplePlaylists) else { return }

        let legacyEntries = (try? context.fetch(
            FetchDescriptor<PlaylistEntry>(predicate: #Predicate { $0.playlist == nil }),
        )) ?? []
        if !legacyEntries.isEmpty {
            let existing = (try? context.fetch(
                FetchDescriptor<Playlist>(predicate: #Predicate { $0.name == "My Playlist" }),
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

    private static func deletePersistentStoreFiles() throws {
        let fileManager = FileManager.default
        guard let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let store = applicationSupport.appendingPathComponent("default.store")
        for suffix in ["", "-shm", "-wal"] {
            let url = URL(fileURLWithPath: store.path + suffix)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
        UserDefaults.standard.set(false, forKey: PreferenceKeys.didMigrateToMultiplePlaylists)
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

private struct DatabaseRecoveryAlert: Identifiable {
    let id = UUID()
    let message: String

    init(error: Error) {
        message = "BeatClikr could not open its local database. You can reset the local database on this device and let iCloud sync restore what it can, or continue with a temporary store so you can recover from another device. Original error: \(error.localizedDescription)"
    }
}
