//
//  PlaybackCoordinator.swift
//  beatclikr
//
//  created by Ben Funk 7/27/26
//

import Foundation
@preconcurrency import MediaPlayer
import UIKit

enum PlaybackMode: Equatable {
    case metronome
    case polyrhythm
}

@MainActor
protocol LockScreenPlaybackControlling: AnyObject {
    func installStopHandler(_ handler: @escaping @MainActor () -> Void)
    func playbackStarted(mode: PlaybackMode)
    func playbackStopped()
}

@MainActor
final class LockScreenPlaybackController: LockScreenPlaybackControlling {
    private var stopHandler: (@MainActor () -> Void)?
    private nonisolated(unsafe) var commandTargets: [Any] = []

    func installStopHandler(_ handler: @escaping @MainActor () -> Void) {
        stopHandler = handler

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        commandCenter.changePlaybackRateCommand.isEnabled = false

        register(commandCenter.playCommand)
        register(commandCenter.pauseCommand)
        register(commandCenter.stopCommand)
        register(commandCenter.togglePlayPauseCommand)
        setStopCommandsEnabled(false)
    }

    func playbackStarted(mode: PlaybackMode) {
        let modeName = switch mode {
        case .metronome:
            "Metronome"
        case .polyrhythm:
            "Polyrhythm"
        }
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: "BeatClikr",
            MPMediaItemPropertyArtist: modeName,
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: 1,
        ]
        if let icon = UIImage(named: "appicondisplay") {
            // The modern request-handler initializer crashes on some devices
            // when SpringBoard requests artwork during metronome playback.
            // This image is static, so the compatibility initializer is safer.
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: icon)
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        setStopCommandsEnabled(true)
        MPNowPlayingInfoCenter.default().playbackState = .playing
    }

    func playbackStopped() {
        setStopCommandsEnabled(false)
        MPNowPlayingInfoCenter.default().playbackState = .stopped
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func register(_ command: MPRemoteCommand) {
        command.isEnabled = true
        let target = command.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stopHandler?()
            }
            return .success
        }
        commandTargets.append(target)
    }

    private func setStopCommandsEnabled(_ enabled: Bool) {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = enabled
        commandCenter.pauseCommand.isEnabled = enabled
        commandCenter.stopCommand.isEnabled = enabled
        commandCenter.togglePlayPauseCommand.isEnabled = enabled
    }
}

@MainActor
final class PlaybackCoordinator: AudioPlaybackService, AudioPlaybackLifecycleDelegate {
    private let audio: any AudioPlaybackService
    private let lockScreenControls: (any LockScreenPlaybackControlling)?

    private(set) var activeMode: PlaybackMode?
    var onMetronomeStopped: (() -> Void)?
    var onPolyrhythmStopped: (() -> Void)?
    var onMetronomeInterrupted: (() -> Void)?
    var onPolyrhythmInterrupted: (() -> Void)?

    var lifecycleDelegate: AudioPlaybackLifecycleDelegate? {
        get { audio.lifecycleDelegate }
        set { audio.lifecycleDelegate = newValue }
    }

    var metronomeDelegate: MetronomeAudioEngineDelegate? {
        get { audio.metronomeDelegate }
        set { audio.metronomeDelegate = newValue }
    }

    var polyrhythmDelegate: PolyrhythmAudioEngineDelegate? {
        get { audio.polyrhythmDelegate }
        set { audio.polyrhythmDelegate = newValue }
    }

    init(
        audio: any AudioPlaybackService = AudioPlayerService.instance,
        lockScreenControls: (any LockScreenPlaybackControlling)? = nil,
    ) {
        self.audio = audio
        self.lockScreenControls = lockScreenControls
        audio.lifecycleDelegate = self
        lockScreenControls?.installStopHandler { [weak self] in
            self?.stopActivePlayback()
        }
    }

    func setupMetronomeAudio(beatName: String, rhythmName: String) throws {
        try audio.setupMetronomeAudio(beatName: beatName, rhythmName: rhythmName)
    }

    func setupPolyrhythmAudio(beatName: String, rhythmName: String) throws {
        try audio.setupPolyrhythmAudio(beatName: beatName, rhythmName: rhythmName)
    }

    func setSoundBank(_ bank: SoundBank) {
        audio.setSoundBank(bank)
    }

    func startMetronome(bpm: Double, subdivisions: Int, accentPattern: [Bool]?) throws {
        if activeMode == .polyrhythm {
            stopPolyrhythm(notifyOwner: true)
        }
        try audio.startMetronome(bpm: bpm, subdivisions: subdivisions, accentPattern: accentPattern)
        activeMode = .metronome
        lockScreenControls?.playbackStarted(mode: .metronome)
    }

    func stopMetronome() {
        stopMetronome(notifyOwner: false)
    }

    private func stopMetronome(notifyOwner: Bool) {
        audio.stopMetronome()
        if activeMode == .metronome {
            activeMode = nil
            lockScreenControls?.playbackStopped()
        }
        if notifyOwner {
            onMetronomeStopped?()
        }
    }

    func updateTempo(bpm: Double, subdivisions: Int) {
        audio.updateTempo(bpm: bpm, subdivisions: subdivisions)
    }

    func setRamp(enabled: Bool, increment: Int, interval: Int) {
        audio.setRamp(enabled: enabled, increment: increment, interval: interval)
    }

    func startPolyrhythm(bpm: Double, beats: Int, against: Int) throws {
        if activeMode == .metronome {
            stopMetronome(notifyOwner: true)
        }
        try audio.startPolyrhythm(bpm: bpm, beats: beats, against: against)
        activeMode = .polyrhythm
        lockScreenControls?.playbackStarted(mode: .polyrhythm)
    }

    func stopPolyrhythm() {
        stopPolyrhythm(notifyOwner: false)
    }

    private func stopPolyrhythm(notifyOwner: Bool) {
        audio.stopPolyrhythm()
        if activeMode == .polyrhythm {
            activeMode = nil
            lockScreenControls?.playbackStopped()
        }
        if notifyOwner {
            onPolyrhythmStopped?()
        }
    }

    func stopAll() {
        stopMetronome(notifyOwner: true)
        stopPolyrhythm(notifyOwner: true)
    }

    private func stopActivePlayback() {
        switch activeMode {
        case .metronome:
            stopMetronome(notifyOwner: true)
        case .polyrhythm:
            stopPolyrhythm(notifyOwner: true)
        case nil:
            lockScreenControls?.playbackStopped()
        }
    }

    func audioPlaybackWasInterrupted() {
        let interruptedMode = activeMode
        activeMode = nil
        lockScreenControls?.playbackStopped()
        switch interruptedMode {
        case .metronome:
            onMetronomeInterrupted?()
        case .polyrhythm:
            onPolyrhythmInterrupted?()
        case nil:
            break
        }
    }
}
