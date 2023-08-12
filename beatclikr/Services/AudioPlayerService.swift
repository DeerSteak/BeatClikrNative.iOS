//
//  AudioPlayerService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/12/23.
//

import Foundation
import AVFoundation

class AudioPlayerService {
    static var instance = AudioPlayerService()
    
    private var starling = Starling.instance
    private var beatName: String {
        didSet {
            starling.load(resource: beatName, type: FileConstants.FileExt, for: .beat)
        }
    }
    private var rhythmName: String {
        didSet {
            starling.load(resource: rhythmName, type: FileConstants.FileExt, for: .rhythm)
        }
    }
        
    init() {
        beatName = FileConstants.ClickHi
        rhythmName = FileConstants.ClickLo
    }
    
    //MARK: Public functions
    
    func playBeat() {
        starling.play(.beat, allowOverlap: false)
    }
    
    func playRhythm() {
        starling.play(.rhythm, allowOverlap: false)
    }
    
    func setupAudioPlayer(beatName: String, rhythmName: String) {
        loadBeatFile(beatName)
        loadRhythmFile(rhythmName)
    }
    
    //MARK: Private helpers
    
    private func loadBeatFile(_ filename: String) {
        beatName = filename
    }
    
    private func loadRhythmFile(_ filename: String) {
        rhythmName = filename
    }
}
