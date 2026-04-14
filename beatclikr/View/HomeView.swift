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
        case .instant:  return ImageConstants.tabInstant
        case .library:  return ImageConstants.tabLibrary
        case .playlist: return ImageConstants.tabPlaylist
        case .settings: return ImageConstants.tabSettings
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
        } else {
            TabView {
                InstantMetronomeView()
                    .tabItem { Label("Instant", systemImage: ImageConstants.tabInstant) }
                SongLibraryView()
                    .tabItem { Label("Library", systemImage: ImageConstants.tabLibrary) }
                PlaylistModeView()
                    .tabItem { Label("Playlist", systemImage: ImageConstants.tabPlaylist) }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: ImageConstants.tabSettings) }
            }
        }
    }
}

#Preview {
    let metronome = MetronomePlaybackViewModel()
    HomeView()
        .environmentObject(metronome)
        .environmentObject(SettingsViewModel())
        .environmentObject(SongLibraryViewModel(metronome: metronome))
        .environmentObject(PlaylistModeViewModel(metronome: metronome))
}
