//
//  beatclikrApp.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import SwiftUI
import SwiftData
import Awesome

@main
struct beatclikrApp: App {
    
    init() {
        AwesomePro.loadFonts(from: Bundle.main)
    }

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(SongLibraryViewModel())
                .environmentObject(MetronomePlaybackViewModel())
        }
        .modelContainer(for: Song.self)
    }
}
