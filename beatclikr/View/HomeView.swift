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
            LibraryView()
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
    let previewContainer = PreviewContainer([Song.self])
    return HomeView()
        .environmentObject(MetronomePlaybackViewModel())
        .environmentObject(SettingsViewModel())
        .environmentObject(SongLibraryViewModel(container: previewContainer.container))
        
}
