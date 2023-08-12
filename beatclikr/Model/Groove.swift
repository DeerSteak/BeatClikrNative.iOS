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
            return "1"
        case .eighth:
            return "2"
        case .triplet:
            return "3"
        case .sixteenth:
            return "4"
        }
    }
}
