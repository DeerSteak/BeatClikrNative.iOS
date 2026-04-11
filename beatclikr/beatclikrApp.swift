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

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(SongLibraryViewModel())
                .environmentObject(MetronomePlaybackViewModel())
                .environmentObject(SettingsViewModel())
        }
        .modelContainer(container)
    }

}
