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
    case oddMeterQuarter = 5
    case oddMeterEighth = 6

    var id: Self { self }
    var description: String {
        switch self {
        case .quarter:         return "Quarter Note"
        case .eighth:          return "Eighth Note"
        case .triplet:         return "Triplet 6/8"
        case .sixteenth:       return "Sixteenth Note"
        case .oddMeterQuarter: return "Odd Quarter"
        case .oddMeterEighth:  return "Odd Eighth"
        }
    }

    var isOddMeter: Bool {
        self == .oddMeterQuarter || self == .oddMeterEighth
    }

    var subdivisions: Int {
        switch self {
        case .oddMeterEighth: return 2
        case .oddMeterQuarter: return 1
        default: return rawValue
        }
    }
}
