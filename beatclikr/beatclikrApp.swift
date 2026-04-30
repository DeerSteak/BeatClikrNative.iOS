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
    @StateObject private var playlistListViewModel: PlaylistListViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    
    init() {
        let config = ModelConfiguration(
            cloudKitDatabase: .private("iCloud.com.bfunkstudios.beatclikr")
        )
        
        do {
            container = try ModelContainer(
                for: Song.self, PlaylistEntry.self, Playlist.self,
                configurations: config
            )
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let context = container.mainContext
        
        // Remove entries whose song was deleted
        let orphaned = (try? context.fetch(
            FetchDescriptor<PlaylistEntry>(predicate: #Predicate { $0.song == nil })
        )) ?? []
        if !orphaned.isEmpty {
            orphaned.forEach { context.delete($0) }
            try? context.save()
        }
        
        // Migrate legacy entries (no playlist) into a default playlist
        let legacyEntries = (try? context.fetch(
            FetchDescriptor<PlaylistEntry>(predicate: #Predicate { $0.playlist == nil })
        )) ?? []
        if !legacyEntries.isEmpty {
            let defaultPlaylist = Playlist(name: "My Playlist")
            context.insert(defaultPlaylist)
            for entry in legacyEntries {
                entry.playlist = defaultPlaylist
            }
            try? context.save()
        }
        
        let metronome = MetronomePlaybackViewModel()
        _metronomeViewModel = StateObject(wrappedValue: metronome)
        _songLibraryViewModel = StateObject(wrappedValue: SongLibraryViewModel())
        _playlistListViewModel = StateObject(wrappedValue: PlaylistListViewModel())
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(songLibraryViewModel)
                .environmentObject(playlistListViewModel)
                .environmentObject(metronomeViewModel)
                .environmentObject(settingsViewModel)
        }
        .modelContainer(container)
    }
}
