//
//  FileConstants.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation
enum FileConstants: String, CaseIterable, Identifiable, CustomStringConvertible, Codable {
    case FileExt = "wav"
    case ClickHi = "clickhi_E5"
    case ClickLo = "clicklo_F5"
    case Cowbell = "cowbell_G#3"
    case CrashL = "crashl_C#3"
    case CrashR = "crashr_A3"
    case HatClosed = "hatclosed_F#2"
    case HatOpen = "hatopen_A#2"
    case Kick = "kick_C2"
    case RideEdge = "rideedge_D#3"
    case RideBell = "ridebell_F3"
    case Silence = "silence_D7"
    case Snare = "snare_D2"
    case Tamb = "tamb_F#3"
    case TomHi = "tomhi_D3"
    case TomLo = "tomlow_A2"
    case TomMid = "tommid_B2"

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
    
    func getNoteNumber() -> Int {
        switch self {
            
        case .FileExt:
            return 99
        case .ClickHi:
            return 76 //E5
        case .ClickLo:
            return 77 //F5
        case .Cowbell:
            return 56 //G#3
        case .CrashL:
            return 49 //C#3
        case .CrashR:
            return 57 //A3
        case .HatClosed:
            return 42 //F#2
        case .HatOpen:
            return 46 //A#2
        case .Kick:
            return 36 //C2
        case .RideEdge:
            return 51 //D#3
        case .RideBell:
            return 53 //F3
        case .Silence:
            return 98 //D7
        case .Snare:
            return 38 //D2
        case .Tamb:
            return 54 //F#3
        case .TomHi:
            return 50 //D3
        case .TomLo:
            return 45 //A2
        case .TomMid:
            return 47 //B2
        }
    }
}
