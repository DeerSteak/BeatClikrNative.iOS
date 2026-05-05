//
//  HomeView.swift
//  beatclikr
//
//  Created by Ben Funk on 9/2/23.
//

import SwiftUI

private enum AppSection: String, CaseIterable, Identifiable {
    case instant, library, playlist, history, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .instant:  return "Instant Metronome"
        case .library:  return "Song Library"
        case .playlist: return "All Playlists"
        case .history:  return "Practice History"
        case .settings: return "Settings"
        }
    }
    var icon: String {
        switch self {
        case .instant:  return ImageConstants.tabInstant
        case .library:  return ImageConstants.tabLibrary
        case .playlist: return ImageConstants.tabPlaylist
        case .history:  return ImageConstants.tabHistory
        case .settings: return ImageConstants.tabSettings
        }
    }
}

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @State private var selectedSection: AppSection? = .instant
    
    var body: some View {
        Group {
            if sizeClass == .regular {
                NavigationSplitView {
                    List(selection: $selectedSection) {
                        ForEach(AppSection.allCases) { section in
                            Label(section.title, systemImage: section.icon)
                                .tag(section)
                        }
                    }
                    .navigationTitle("BeatClikr")
                } detail: {
                    switch selectedSection {
                    case .instant:  InstantMetronomeView()
                    case .library:  SongLibraryView()
                    case .playlist: PlaylistListView()
                    case .history:  PracticeHistoryView()
                    case .settings: SettingsView()
                    case nil:       InstantMetronomeView()
                    }
                }
#if targetEnvironment(macCatalyst)
                .onAppear {
                    (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.titlebar?.titleVisibility = .hidden
                }
#endif
            } else {
                TabView {
                    InstantMetronomeView()
                        .tabItem { Label("Instant", systemImage: ImageConstants.tabInstant) }
                    SongLibraryView()
                        .tabItem { Label("Library", systemImage: ImageConstants.tabLibrary) }
                    PlaylistListView()
                        .tabItem { Label("Playlist", systemImage: ImageConstants.tabPlaylist) }
                    PracticeHistoryView()
                        .tabItem { Label("History", systemImage: ImageConstants.tabHistory) }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: ImageConstants.tabSettings) }
                }
                .tint(Color.appPrimary)
            }
        }
        .alert("Practice Reminders", isPresented: $settingsViewModel.showCrossDeviceReminderPrompt) {
            Button("Allow Notifications") {
                settingsViewModel.allowRemindersFromOtherDevice()
            }
            Button("Not Now", role: .cancel) {
                settingsViewModel.declineRemindersFromOtherDevice()
            }
        } message: {
            Text("Practice reminders are enabled on another device. Allow BeatClikr to send them on this device too?")
        }
        .alert("Notifications Disabled", isPresented: $settingsViewModel.showPermissionDeniedAlert) {
            Button("Open Settings") {
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
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Practice reminders require notification permissions. Please enable them in Settings.")
        }
    }
}

#Preview {
    let metronome = MetronomePlaybackViewModel()
    HomeView()
        .environmentObject(metronome)
        .environmentObject(SettingsViewModel())
        .environmentObject(SongLibraryViewModel())
        .environmentObject(PlaylistListViewModel())
}
