//
//  AudioPlayerService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/12/23.
//

import Foundation
import AudioKit
import AVFoundation

@MainActor
class AudioPlayerService: HasAudioEngine {
    static let instance = AudioPlayerService()

    nonisolated(unsafe) internal let engine = AudioEngine()

    #if targetEnvironment(simulator)
    // Use AudioPlayer in simulator (has latency but doesn't crash)
    private var beatPlayer: AudioPlayer?
    private var rhythmPlayer: AudioPlayer?
    private let mixer = Mixer()
    #else
    // Use AppleSampler on real devices (low latency, sample-accurate)
    private let sampler = AppleSampler()
    #endif

    var sounds: [SoundFile]

    private var beatSound: SoundFile? {
        didSet {
            #if targetEnvironment(simulator)
            if let sound = beatSound, let file = sound.audioFile {
                beatPlayer?.stop()
                beatPlayer?.detach()
                beatPlayer = AudioPlayer(file: file)
                beatPlayer?.volume = 1.0
                if let player = beatPlayer {
                    mixer.addInput(player)
                }
            }
            #endif
        }
    }

    private var beatName: String {
        didSet {
            beatSound = sounds.first(where: { sound in
                sound.displayName == beatName
            })
        }
    }

    private var rhythmSound: SoundFile? {
        didSet {
            #if targetEnvironment(simulator)
            if let sound = rhythmSound, let file = sound.audioFile {
                rhythmPlayer?.stop()
                rhythmPlayer?.detach()
                rhythmPlayer = AudioPlayer(file: file)
                rhythmPlayer?.volume = 1.0
                if let player = rhythmPlayer {
                    mixer.addInput(player)
                }
            }
            #endif
        }
    }

    private var rhythmName: String {
        didSet {
            rhythmSound = sounds.first(where: { sound in
                sound.displayName == rhythmName
            })
        }
    }

    init() {
        beatName = FileConstants.ClickHi.rawValue
        rhythmName = FileConstants.ClickLo.rawValue

        // Configure audio session
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        sounds = [SoundFile]()
        for file in FileConstants.allCases {
            if file != FileConstants.Silence && file != FileConstants.FileExt {
                let sound = SoundFile(file.rawValue, file: "\(file.rawValue).\(FileConstants.FileExt.rawValue)", note: file.getNoteNumber())
                sounds.append(sound)
            }
        }

        #if targetEnvironment(simulator)
        // Simulator: Use AudioPlayer (testing only, has latency)
        beatSound = sounds.first(where: { $0.displayName == beatName })
        rhythmSound = sounds.first(where: { $0.displayName == rhythmName })
        if beatSound?.audioFile == nil {
            print("Warning: Beat sound file not loaded for \(beatName)")
        }
        if rhythmSound?.audioFile == nil {
            print("Warning: Rhythm sound file not loaded for \(rhythmName)")
        }
        engine.output = mixer
        #else
        // Real Device: Use AppleSampler (low latency, accurate timing)
        engine.output = sampler
        do {
            let files = sounds.compactMap { $0.audioFile }
            if files.count != sounds.count {
                print("Warning: Only loaded \(files.count) of \(sounds.count) sound files")
            }
            try sampler.loadAudioFiles(files)
        } catch {
            print("couldn't load files: \(error)")
        }
        #endif

        do {
            try engine.start()
        } catch {
            print("Can't start engine: \(error)")
        }
    }

    //MARK: Public functions

    func playBeat() {
        #if targetEnvironment(simulator)
        guard let player = beatPlayer else { return }
        player.play()
        #else
        if let beatSound = beatSound {
            sampler.play(noteNumber: MIDINoteNumber(beatSound.midiNote))
        }
        #endif
    }

    func playRhythm() {
        #if targetEnvironment(simulator)
        guard let player = rhythmPlayer else { return }
        player.play()
        #else
        if let rhythmSound = rhythmSound {
            sampler.play(noteNumber: MIDINoteNumber(rhythmSound.midiNote))
        }
        #endif
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
