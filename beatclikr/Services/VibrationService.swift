//
//  VibrationService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/6/23.
//

import Foundation
import UIKit

class VibrationService {
    static var instance = VibrationService()
    
    private var beatGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private var rhythmGenerator = UIImpactFeedbackGenerator(style: .light)
    
    func vibrateBeat() {
        beatGenerator.impactOccurred()
    }
    
    func vibrateRhythm() {
        rhythmGenerator.impactOccurred()
    }
}
