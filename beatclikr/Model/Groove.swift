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

    var id: Self {
        self
    }

    var description: String {
        switch self {
        case .quarter: "Quarter Note"
        case .eighth: "Eighth Note"
        case .triplet: "Triplet 6/8"
        case .sixteenth: "Sixteenth Note"
        case .oddMeterQuarter: "Odd Quarter"
        case .oddMeterEighth: "Odd Eighth"
        }
    }

    var isOddMeter: Bool {
        self == .oddMeterQuarter || self == .oddMeterEighth
    }

    var subdivisions: Int {
        switch self {
        case .oddMeterEighth: 2
        case .oddMeterQuarter: 1
        default: rawValue
        }
    }
}
