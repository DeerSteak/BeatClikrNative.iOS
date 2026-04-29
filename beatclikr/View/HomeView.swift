//
//  HomeView.swift
//  beatclikr
//
//  Created by Ben Funk on 9/2/23.
//

import SwiftUI

private enum AppSection: String, CaseIterable, Identifiable {
    case instant, library, playlist, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .instant:  return "Instant"
        case .library:  return "Library"
        case .playlist: return "Playlist"
        case .settings: return "Settings"
        }
    }
    var icon: String {
        switch self {
        case .instant:  return "metronome"
        case .library:  return "list.bullet.rectangle"
        case .playlist: return "music.note.list"
        case .settings: return "gear"
        }
    }
}

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedSection: AppSection? = .instant
    
    var body: some View {
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
                case .playlist: PlaylistModeView()
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
                    .tabItem { Label("Instant", systemImage: "metronome") }
                SongLibraryView()
                    .tabItem { Label("Library", systemImage: "list.bullet.rectangle") }
                PlaylistModeView()
                    .tabItem { Label("Playlist", systemImage: "music.note.list") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
            .tint(Color.appPrimary)
        }
    }
}

#Preview {
    let metronome = MetronomePlaybackViewModel()
    HomeView()
        .environmentObject(metronome)
        .environmentObject(SettingsViewModel())
        .environmentObject(SongLibraryViewModel())
        .environmentObject(PlaylistModeViewModel())
}
