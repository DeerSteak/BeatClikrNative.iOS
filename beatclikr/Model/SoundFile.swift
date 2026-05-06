//
//  SoundFile.swift
//  beatclikr
//
//  Created by Ben Funk on 8/13/23.
//

import AVFoundation

struct SoundFile {
    var displayName: String
    var fileName: String
    var midiNote: Int
    var audioFile: AVAudioFile?

    init(_ prettyName: String, file: String, note: Int) {
        displayName = prettyName
        fileName = file
        midiNote = note

        guard let url = Bundle.main.resourceURL?.appendingPathComponent(file) else { return }
        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch {
            print("Could not load \(fileName): \(error)")
        }
    }
}
