//
//  PreviewDataContainer.swift
//  beatclikr
//
//  Created by Ben Funk on 10/12/23.
//

import Foundation
import SwiftData

struct PreviewContainer {
    let container: ModelContainer!
    
    init(_ types: [any PersistentModel.Type], isStoredInMemoryOnly: Bool = true) {
        let schema = Schema(types)
        let config = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
        self.container = try! ModelContainer(for: schema, configurations: [config])
    }
    
    func addSong() {
        let song = Song(title: "My favorite", artist: "The Best", beatsPerMinute: 120, beatsPerMeasure: 4, groove: .eighth)
        Task { @MainActor in
            container.mainContext.insert(song)
        }
    }
}
