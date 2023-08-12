//
//  FileConstants.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation
enum FileConstants: String, CaseIterable, Identifiable, CustomStringConvertible, Codable {
    case FileExt = "wav"
    
    case ClickHi = "clickhi"
    case ClickLo = "clicklo"
    case Cowbell = "cowbell"
    case CrashL = "crashl"
    case CrashR = "crashr"
    case HatClosed = "hatclosed"
    case HatOpen = "hatopen"
    case Kick = "kick"
    case RideEdge = "ride"
    case RideBell = "ridebell"
    case Silence = "silence"
    case Snare = "snare"
    case Tamb = "tamb"
    case TomHi = "tomhi"
    case TomLo = "tomlow"
    case TomMid = "tommid"

    var id: Self {self}
    
    var description: String {
        switch self {
        case .ClickHi:
            return "Click Hi"
        case .ClickLo:
            return "Click Lo"
        case .Cowbell:
            return "Cowbell"
        case .CrashL:
            return "Crash (Left)"
        case .FileExt:
            return ".wav"
        case .CrashR:
            return "Crash (Right)"
        case .HatClosed:
            return "Hi-Hat (Closed)"
        case .HatOpen:
            return "Hi-Hat (Open)"
        case .Kick:
            return "Kick"
        case .RideEdge:
            return "Ride (Edge)"
        case .RideBell:
            return "Ride (Bell)"
        case .Silence:
            return "Silence"
        case .Snare:
            return "Snare"
        case .Tamb:
            return "Tamourine"
        case .TomHi:
            return "Tom (High)"
        case .TomLo:
            return "Tom (Low)"
        case .TomMid:
            return "Tom (Mid)"
        }
    }
}
