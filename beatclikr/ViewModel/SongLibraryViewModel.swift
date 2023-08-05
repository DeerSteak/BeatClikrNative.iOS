//
//  SongLibraryViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation
import SwiftData

class SongLibraryViewModel : ObservableObject {        
    private var context: ModelContext
    
    init() {
        let container = try! ModelContainer(for: Song.self)
        context = ModelContext(container)
    }
}
