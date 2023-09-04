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


    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(SongLibraryViewModel())
                .environmentObject(MetronomePlaybackViewModel())
        }
        .modelContainer(for: Song.self)
    }
}
