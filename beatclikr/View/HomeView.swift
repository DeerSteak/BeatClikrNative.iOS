//
//  HomeView.swift
//  beatclikr
//
//  Created by Ben Funk on 9/2/23.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
            InstantMetronomeView()
                .tabItem {
                    Label("Instant", systemImage: "metronome")
                }
            SongLibraryView()
                .tabItem {
                    Label("Library", systemImage: "list.bullet.rectangle")
                }
            PlaylistModeView()
                .tabItem {
                    Label("Playlist", systemImage: "music.note.list")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
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
