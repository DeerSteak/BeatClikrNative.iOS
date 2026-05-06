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

    var id: Self {
        self
    }

    var description: String {
        switch self {
        case .ClickHi:
            "Click Hi"
        case .ClickLo:
            "Click Lo"
        case .Cowbell:
            "Cowbell"
        case .CrashL:
            "Crash (Left)"
        case .FileExt:
            ".wav"
        case .CrashR:
            "Crash (Right)"
        case .HatClosed:
            "Hi-Hat (Closed)"
        case .HatOpen:
            "Hi-Hat (Open)"
        case .Kick:
            "Kick"
        case .RideEdge:
            "Ride (Edge)"
        case .RideBell:
            "Ride (Bell)"
        case .Silence:
            "Silence"
        case .Snare:
            "Snare"
        case .Tamb:
            "Tamourine"
        case .TomHi:
            "Tom (High)"
        case .TomLo:
            "Tom (Low)"
        case .TomMid:
            "Tom (Mid)"
        }
    }

    func getNoteNumber() -> Int {
        switch self {
        case .FileExt:
            99
        case .ClickHi:
            76 // E5
        case .ClickLo:
            77 // F5
        case .Cowbell:
            56 // G#3
        case .CrashL:
            49 // C#3
        case .CrashR:
            57 // A3
        case .HatClosed:
            42 // F#2
        case .HatOpen:
            46 // A#2
        case .Kick:
            36 // C2
        case .RideEdge:
            51 // D#3
        case .RideBell:
            53 // F3
        case .Silence:
            98 // D7
        case .Snare:
            38 // D2
        case .Tamb:
            54 // F#3
        case .TomHi:
            50 // D3
        case .TomLo:
            45 // A2
        case .TomMid:
            47 // B2
        }
    }
}
