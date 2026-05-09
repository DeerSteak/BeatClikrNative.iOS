//
//  HomeView.swift
//  beatclikr
//
//  Created by Ben Funk on 9/2/23.
//

import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case metronome, polyrhythm, library, playlist, history, settings
    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .metronome: "Metronome"
        case .polyrhythm: "Polyrhythm"
        case .library: "Song Library"
        case .playlist: "All Playlists"
        case .history: "Practice History"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .metronome: ImageConstants.tabMetronome
        case .polyrhythm: ImageConstants.tabPolyrhythm
        case .library: ImageConstants.tabLibrary
        case .playlist: ImageConstants.tabPlaylist
        case .history: ImageConstants.tabHistory
        case .settings: ImageConstants.tabSettings
        }
    }
}

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var polyrhythmViewModel: PolyrhythmViewModel
    @Binding private var selectedSection: AppSection?
    @State private var splashVisible = true
    @State private var splashOpacity: Double = 1
    @State private var logoOpacity: Double = 0
    @State private var logoScale: Double = 0.85

    init(selectedSection: Binding<AppSection?>) {
        _selectedSection = selectedSection
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                NavigationSplitView {
                    List(selection: $selectedSection) {
                        ForEach(AppSection.allCases) { section in
                            Group {
                                if section == .metronome {
                                    Label {
                                        Text(section.title)
                                    } icon: {
                                        Image(ImageConstants.tabMetronome)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22)
                                    }
                                } else {
                                    Label(section.title, systemImage: section.icon)
                                }
                            }
                            .tag(section)
                        }
                    }
                    .navigationTitle("BeatClikr")
                    .navigationSplitViewColumnWidth(min: 300, ideal: 300, max: 300)
                } detail: {
                    Group {
                        switch selectedSection {
                        case .metronome:
                            MetronomeView()
                                .navigationTitle("Metronome")
                        case .polyrhythm:
                            PolyrhythmView()
                                .environmentObject(polyrhythmViewModel)
                                .navigationTitle("Polyrhythm")
                        case .library: SongLibraryView()
                        case .playlist: PlaylistListView()
                        case .history: PracticeHistoryView()
                        case .settings: SettingsView()
                        case nil:
                            MetronomeView()
                                .navigationTitle("Metronome")
                        }
                    }
                    .frame(maxWidth: 700, alignment: .center)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGroupedBackground))
                }
                #if targetEnvironment(macCatalyst)
                .onAppear {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        scene.titlebar?.titleVisibility = .hidden
                        scene.sizeRestrictions?.minimumSize = CGSize(width: 1020, height: 680)
                        scene.sizeRestrictions?.maximumSize = CGSize(width: 1020, height: 2000)
                        scene.sizeRestrictions?.allowsFullScreen = false
                    }
                }
                #endif
            } else {
                TabView(selection: compactSelectedSection) {
                    MetronomeContainerView()
                        .tabItem { Label("Metronome", image: ImageConstants.tabMetronome) }
                        .tag(AppSection.metronome)
                    SongLibraryView()
                        .tabItem { Label("Library", systemImage: ImageConstants.tabLibrary) }
                        .tag(AppSection.library)
                    PlaylistListView()
                        .tabItem { Label("Playlist", systemImage: ImageConstants.tabPlaylist) }
                        .tag(AppSection.playlist)
                    PracticeHistoryView()
                        .tabItem { Label("History", systemImage: ImageConstants.tabHistory) }
                        .tag(AppSection.history)
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: ImageConstants.tabSettings) }
                        .tag(AppSection.settings)
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

    private var compactSelectedSection: Binding<AppSection> {
        Binding(
            get: {
                switch selectedSection {
                case .library, .playlist, .history, .settings:
                    selectedSection ?? .metronome
                case .metronome, .polyrhythm, nil:
                    .metronome
                }
            },
            set: { selectedSection = $0 },
        )
    }
}

#Preview {
    @Previewable @State var selectedSection: AppSection? = .metronome

    HomeView(selectedSection: $selectedSection)
        .environmentObject(MetronomePlaybackViewModel())
        .environmentObject(PolyrhythmViewModel())
        .environmentObject(SettingsViewModel())
        .environmentObject(SongLibraryViewModel())
        .environmentObject(PlaylistListViewModel())
}
