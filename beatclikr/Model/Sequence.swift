//
//  Sequence.swift
//  beatclikr
//
//  Created by Ben Funk on 6/19/26.
//

import Foundation
import SwiftData

@Model
final class SavedSequence: Identifiable {
    var id: String?
    var name: String?
    var tempo: Double?
    var beatsPerMeasure: Int?
    var measuresCount: Int?
    var subdivisionsPerBeat: Int?
    var patternData: Data?
    var createdAt: Date?
    var modifiedAt: Date?

    init(name: String, tempo: Double, beatsPerMeasure: Int,
         measuresCount: Int, subdivisionsPerBeat: Int, patternData: Data)
    {
        id = UUID().uuidString
        self.name = name
        self.tempo = tempo
        self.beatsPerMeasure = beatsPerMeasure
        self.measuresCount = measuresCount
        self.subdivisionsPerBeat = subdivisionsPerBeat
        self.patternData = patternData
        createdAt = Date()
        modifiedAt = Date()
    }
}
