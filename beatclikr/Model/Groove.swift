//
//  Groove.swift
//  beatclikr
//
//  Created by Ben Funk on 8/9/23.
//

import Foundation
enum Groove: Int, CaseIterable, Identifiable, CustomStringConvertible, Codable {
    case quarter = 1
    case eighth = 2
    case triplet = 3
    case sixteenth = 4
    
    var id: Self {self}
    var description: String {
        switch self {
        case .quarter:
            return "Quarter"
        case .eighth:
            return "Eighth"
        case .triplet:
            return "Triplet Eighth"
        case .sixteenth:
            return "Sixteenth"
        }
    }
}
