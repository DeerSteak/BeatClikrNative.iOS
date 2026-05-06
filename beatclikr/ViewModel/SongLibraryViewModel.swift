//
//  SongLibraryViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class SongLibraryViewModel: SongNavigationViewModel {
    func deleteItems(offsets: IndexSet, items: [Song], context: ModelContext) {
        withAnimation {
            for index in offsets {
                context.delete(items[index])
            }
            do {
                try context.save()
            } catch {
                print("Failed to delete songs: \(error)")
            }
        }
    }
}
