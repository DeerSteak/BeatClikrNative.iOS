//
//  Item.swift
//  beatclikr
//
//  Created by Ben Funk on 8/3/23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
