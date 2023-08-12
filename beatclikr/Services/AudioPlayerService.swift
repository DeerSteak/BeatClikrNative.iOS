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
    
    private var beatFile: AVAudioFile?
    private var rhythmFile: AVAudioFile?
    
    private var beatBuffer: AVAudioPCMBuffer?
    private var rhythmBuffer: AVAudioPCMBuffer?
   
    private var subdivisionLengthInSamples: Int = 0;
   
    private let SAMPLE_RATE: Int = 44100
    
    private let audioEngine: AVAudioEngine
    private let playerNode: AVAudioPlayerNode
    
    private var nodesConnected: Bool = false
    
    init() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        audioEngine.attach(playerNode)
    }
    
    //MARK: Public functions
    
    func playBeat() {
        if beatBuffer != nil {
            playerNode.scheduleBuffer(beatBuffer!)
        }
    }
    
    func playRhythm() {
        if rhythmBuffer != nil {
            playerNode.scheduleBuffer(rhythmBuffer!)
        }
    }
    
    func setSubdivisionLengthInSamples(_ milliseconds: Double) {
        subdivisionLengthInSamples = Int((milliseconds * Double(SAMPLE_RATE)) / Double(1000))
    }
    
    func setupAudioPlayer(beatName: String, rhythmName: String, milliseconds: Double) {
        setSubdivisionLengthInSamples(milliseconds)
        loadBeatFile(beatName)
        loadRhythmFile(rhythmName)
        if !nodesConnected && beatFile != nil {
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: beatFile!.processingFormat)
            audioEngine.prepare()
            do {
                try audioEngine.start()
            } catch {
                print("Error starting audio engine: \(error)")
                return
            }            
            nodesConnected = true
        }
    }
    
    //MARK: Private helpers
    
    private func loadBeatFile(_ filename: String) {
        guard let uri = Bundle.main.url(forResource: filename, withExtension: FileConstants.FileExt) else { return }
        do {
            try beatFile = AVAudioFile(forReading: uri)
        } catch {
            print("Unable to load file \(filename): \(error)")
            return
        }
        beatBuffer = AVAudioPCMBuffer(pcmFormat: beatFile!.processingFormat, frameCapacity: AVAudioFrameCount(subdivisionLengthInSamples))
        if (beatBuffer != nil && beatFile != nil) {
            do {
                try beatFile!.read(into: beatBuffer!)
            } catch {
                print("Unable to read \(filename) into buffer: \(error)")
            }
        }
    }
    
    private func loadRhythmFile(_ filename: String) {
        guard let uri = Bundle.main.url(forResource: filename, withExtension: FileConstants.FileExt) else { return }
        do {
            try rhythmFile = AVAudioFile(forReading: uri)
        } catch {
            print("Unable to load file \(filename): \(error)")
            return
        }
        rhythmBuffer = AVAudioPCMBuffer(pcmFormat: rhythmFile!.processingFormat, frameCapacity: AVAudioFrameCount(subdivisionLengthInSamples))
        if (rhythmBuffer != nil && rhythmFile != nil) {
            do {
                try rhythmFile!.read(into: rhythmBuffer!)
            } catch {
                print("Unable to read \(filename) into buffer: \(error)")
            }
        }
    }
}
