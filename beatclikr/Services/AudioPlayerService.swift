//
//  AudioPlayerService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/12/23.
//

import Foundation
import AudioKit

class AudioPlayerService: HasAudioEngine {
    static var instance = AudioPlayerService()
    
    internal let engine = AudioEngine()
    private let sampler = AppleSampler()
    
    var sounds: [SoundFile]
    
    //private var starling = Starling.instance
    
    private var beatSound: SoundFile?
    private var beatName: String {
        didSet {
            //starling.load(resource: beatName, type: FileConstants.FileExt.rawValue, for: .beat)
            beatSound = sounds.first(where: { sound in
                sound.displayName == beatName
            })
        }
    }
    
    private var rhythmSound: SoundFile?
    private var rhythmName: String {
        didSet {
            //starling.load(resource: rhythmName, type: FileConstants.FileExt.rawValue, for: .rhythm)
            rhythmSound = sounds.first(where: { sound in
                sound.displayName == rhythmName
            })
        }
    }
        
    init() {
        beatName = FileConstants.ClickHi.rawValue
        rhythmName = FileConstants.ClickLo.rawValue
        
        engine.output = sampler
        do {
            try engine.start()
        } catch {
            print("Can't start engine: \(error)")
        }
        
        sounds = [SoundFile]()
        for file in FileConstants.allCases {
            if file != FileConstants.Silence && file != FileConstants.FileExt {
                let sound = SoundFile(file.rawValue, file: "\(file.rawValue).\(FileConstants.FileExt.rawValue)", note: file.getNoteNumber())
                sounds.append(sound)
            }
        }
        
        do {
            let files = sounds.map { $0.audioFile! }
            try sampler.loadAudioFiles(files)
        } catch {
            print("couldn't load files: \(error)")
        }
    }
    
    //MARK: Public functions
    
    func playBeat() {
        //starling.play(.beat)
        if (beatSound != nil) {
            sampler.play(noteNumber: MIDINoteNumber(beatSound!.midiNote))
        }
    }
    
    func playRhythm() {
        //starling.play(.rhythm)
        if (rhythmSound != nil) {
            sampler.play(noteNumber: MIDINoteNumber(rhythmSound!.midiNote))
        }
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
