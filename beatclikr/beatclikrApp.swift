//
//  beatclikrApp.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftUI
import SwiftData
@main
struct beatclikrApp: App {
    
    let container: ModelContainer
    
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
    }
    
    @StateObject private var songLibraryViewModel = SongLibraryViewModel()
    @StateObject private var playlistModeViewModel = PlaylistModeViewModel()
    @StateObject private var metronomeViewModel = MetronomePlaybackViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()

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
