//
//  FileConstants.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation
struct FileConstants {
    static let FileExt: String = "wav"
    
    static let ClickHi: String = "clickhi"
    static let ClickLo: String = "clicklo"
    static let Cowbell: String = "cowbell"
    static let CrashL: String = "crashl"
    static let CrashR: String = "crashr"
    static let HatClosed: String = "hatclosed"
    static let HatOpen: String = "hatopen"
    static let Kick: String = "kick"
    static let RideEdge: String = "ride"
    static let RideBell: String = "ridebell"
    static let Silence: String = "silence"
    static let Snare: String = "snare"
    static let Tamb: String = "tamb"
    static let TomHi: String = "tomhi"
    static let TomLo: String = "tomlow"
    static let TomMid: String = "tommid"
    
    static func isValid(val: String) -> Bool {
        return val == ClickHi || val == ClickLo || val == Cowbell
        || val == CrashL || val == CrashR || val == HatClosed
        || val == HatOpen || val == Kick || val == RideEdge
        || val == RideBell || val == Silence || val == Snare
        || val == Tamb || val == TomHi || val == TomLo
        || val == TomMid
    }
    
    static let rhythmInstruments: [String] = [ClickHi, ClickLo, Cowbell, HatClosed, HatOpen, Kick, RideEdge, RideBell, Snare, Tamb, TomHi, TomMid, TomLo]
    static let beatInstruments: [String] = [ClickHi, ClickLo, Cowbell, CrashL, CrashR, HatClosed, HatOpen, Kick, RideEdge, RideBell, Snare, Tamb, TomHi, TomMid, TomLo]
}
