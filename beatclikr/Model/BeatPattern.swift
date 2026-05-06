//
//  BeatPattern.swift
//  beatclikr
//
//  Created by Ben Funk on 5/5/26.
//

import Foundation

enum BeatPattern: String, CaseIterable, Identifiable, Codable {
    // 5/8
    case fiveEightA    = "3,2"
    case fiveEightB    = "2,3"
    // 7/8
    case sevenEightA   = "3,2,2"
    case sevenEightB   = "2,2,3"
    case sevenEightC   = "2,3,2"
    // 9/8
    case nineEightA    = "2,2,2,3"
    case nineEightB    = "3,3,3"
    // 11/8
    case elevenEightA  = "2,2,3,2,2"
    case elevenEightB  = "3,3,2,3"
    // 13/8
    case thirteenEightA = "3,2,2,3,3"
    case thirteenEightB = "2,3,2,3,3"
    // 15/8
    case fifteenEightA  = "3,3,3,3,3"
    case fifteenEightB  = "2,3,2,3,2,3"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .fiveEightA:     return "5 (3+2)"
        case .fiveEightB:     return "5 (2+3)"
        case .sevenEightA:    return "7 (3+2+2)"
        case .sevenEightB:    return "7 (2+2+3)"
        case .sevenEightC:    return "7 (2+3+2)"
        case .nineEightA:     return "9 (2+2+2+3)"
        case .nineEightB:     return "9 (3+3+3)"
        case .elevenEightA:   return "11 (2+2+3+2+2)"
        case .elevenEightB:   return "11 (3+3+2+3)"
        case .thirteenEightA: return "13 (3+2+2+3+3)"
        case .thirteenEightB: return "13 (2+3+2+3+3)"
        case .fifteenEightA:  return "15 (3+3+3+3+3)"
        case .fifteenEightB:  return "15 (2+3+2+3+2+3)"
        }
    }

    // Converts "3,2,2" into [true, false, false, true, false, true, false]
    var accentArray: [Bool] {
        let groups = rawValue.split(separator: ",").compactMap { Int($0) }
        return groups.flatMap { count in
            [true] + Array(repeating: false, count: count - 1)
        }
    }
}
