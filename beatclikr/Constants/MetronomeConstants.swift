//
//  MetronomeConstants.swift
//  beatclikr
//
//  Created by Ben Funk on 4/10/26.
//

import Foundation

enum MetronomeConstants {
    // BPM (Beats Per Minute) constraints
    static let minBPM: Double = 30
    static let maxBPM: Double = 240

    // Visual sizing
    static let playerViewDefaultSize: CGFloat = 80
    static let playerViewToolbarSize: CGFloat = 30

    // Animation
    static let iconScaleMin: CGFloat = 0.5
    static let iconScaleMax: CGFloat = 1.0

    // Timing (in seconds)
    static let timerCheckInterval: TimeInterval = 0.001 // 1ms for high-precision checks
    static let firstBeatDelay: TimeInterval = 0.067 // 67ms delay to ensure timer starts before first beat
    static let lookaheadTolerance: TimeInterval = 0.002 // 2ms lookahead for beat firing
}
