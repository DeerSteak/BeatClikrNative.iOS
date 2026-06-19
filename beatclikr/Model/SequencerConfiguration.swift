//
//  SequencerConfiguration.swift
//  beatclikr
//
//  Created by Ben Funk on 6/19/26.
//

import Foundation

struct SequencerConfiguration: Equatable, Codable {
    var tempo: Double = 120.0
    var beatsPerMeasure: Int = 4
    var measuresCount: Int = 4
    var subdivisionsPerBeat: Int = 4
    
    var totalSteps: Int {
        beatsPerMeasure * measuresCount * subdivisionsPerBeat
    }
    
    func validate() -> Bool {
        tempo >= 40 && tempo <= 240 &&
        beatsPerMeasure >= 1 && beatsPerMeasure <= 8 &&
        measuresCount >= 1 && measuresCount <= 8 &&
        subdivisionsPerBeat >= 1 && subdivisionsPerBeat <= 4
    }
}
