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
            starling.load(resource: beatName, type: FileConstants.FileExt.rawValue, for: .beat)
        }
    }
    private var rhythmName: String {
        didSet {
            starling.load(resource: rhythmName, type: FileConstants.FileExt.rawValue, for: .rhythm)
        }
    }
        
    init() {
        beatName = FileConstants.ClickHi.rawValue
        rhythmName = FileConstants.ClickLo.rawValue
    }
    
    //MARK: Public functions
    
    func playBeat() {
        starling.play(.beat)
    }
    
    func playRhythm() {
        starling.play(.rhythm)
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
