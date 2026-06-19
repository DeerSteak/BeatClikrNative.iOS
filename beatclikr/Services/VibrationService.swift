//
//  VibrationService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/6/23.
//

import Foundation
import UIKit

@MainActor
class VibrationService {
    static let instance = VibrationService()

    private var beatGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private var rhythmGenerator = UIImpactFeedbackGenerator(style: .soft)

    func prepare() {
        beatGenerator.prepare()
        rhythmGenerator.prepare()
    }

    func vibrateBeat() {
        beatGenerator.impactOccurred()
        beatGenerator.prepare()
    }

    func vibrateRhythm() {
        rhythmGenerator.impactOccurred()
        rhythmGenerator.prepare()
    }
}
