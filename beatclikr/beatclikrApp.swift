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
            LibraryView()
                .environmentObject(SongLibraryViewModel())
        }
        .modelContainer(for: Song.self)
    }
}
