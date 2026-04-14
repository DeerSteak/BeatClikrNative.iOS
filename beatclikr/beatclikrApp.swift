//
//  beatclikrApp.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftUI
import SwiftData

@main
@MainActor
struct beatclikrApp: App {
    
    let container: ModelContainer
    
    @StateObject private var metronomeViewModel: MetronomePlaybackViewModel
    @StateObject private var songLibraryViewModel: SongLibraryViewModel
    @StateObject private var playlistModeViewModel: PlaylistModeViewModel
    @StateObject private var settingsViewModel: SettingsViewModel

    init() {
        let config = ModelConfiguration(
            cloudKitDatabase: .private("iCloud.com.bfunkstudios.beatclikr")
        )
        
        do {
            container = try ModelContainer(
                for: Song.self, PlaylistEntry.self,
                configurations: config
            )
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let metronome = MetronomePlaybackViewModel()
        _metronomeViewModel = StateObject(wrappedValue: metronome)
        _songLibraryViewModel = StateObject(wrappedValue: SongLibraryViewModel())
        _playlistModeViewModel = StateObject(wrappedValue: PlaylistModeViewModel())
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel())
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(songLibraryViewModel)
                .environmentObject(playlistModeViewModel)
                .environmentObject(metronomeViewModel)
                .environmentObject(settingsViewModel)
        }
        .modelContainer(container)
    }
    
}
