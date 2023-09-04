//
//  MetronomePlaybackViewModel.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import Foundation
import Observation

class MetronomePlaybackViewModel: ObservableObject {
    
    let metronome = MetronomeService.instance
    let defaults = UserDefaultsService.instance
    
    @Published var imageName: String = ImageConstants.rhythm
    
    @Published var isPlaying: Bool = false
    @Published var beatsPerMinute: Double = UserDefaultsService.instance.instantBpm {
        didSet {
            if clickerType == .instant {
                Song.instantSong.beatsPerMinute = beatsPerMinute
                defaults.instantBpm = beatsPerMinute
            }
        }
    }
    
    @Published var selectedGroove: Groove = UserDefaultsService.instance.instantGroove {
        didSet {
            if clickerType == .instant {
                Song.instantSong.groove = selectedGroove
                defaults.instantGroove = selectedGroove
            }
        }
    }
    
    @Published var beat: FileConstants = UserDefaultsService.instance.instantBeat {
        didSet {
            if clickerType == .instant {
                defaults.instantBeat = beat
            } else {
                defaults.playlistBeat = beat
            }
        }
    }
    
    @Published var rhythm: FileConstants = UserDefaultsService.instance.instantRhythm {
        didSet {
            if clickerType == .instant {
                defaults.instantRhythm = rhythm
            } else {
                defaults.playlistRhythm = rhythm
            }
        }
    }
    
    @Published var clickerType: ClickerType = .instant {
        didSet {
            resetMetronome()
        }
    }
    
    private var song: Song
    
    init() {
        song = Song.instantSong
        song.groove = defaults.instantGroove
        song.beatsPerMinute = defaults.instantBpm
        beat = defaults.instantBeat
        rhythm = defaults.instantRhythm
        clickerType = .instant
    }
    
    func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            metronome.start()
        } else {
            metronome.stop()
        }
    }
    
    func setupMetronome(song: Song) {
        self.song = song
        isPlaying = true
        metronome.setup(beatName: beat.rawValue, rhythmName: rhythm.rawValue, song: song)
    }
    
    func stop() {
        if isPlaying {
            isPlaying.toggle()
            metronome.stop()
        }
    }
        
    func resetMetronome() {
        if isPlaying {
            metronome.stop()
        }
        if clickerType == .instant {
            beat = defaults.instantBeat
            rhythm = defaults.instantRhythm
        } else {
            beat = defaults.playlistBeat
            rhythm = defaults.playlistRhythm
        }
        metronome.setup(beatName: beat.rawValue, rhythmName: rhythm.rawValue, song: song)
        if isPlaying {
            metronome.start()
        }
    }
}
