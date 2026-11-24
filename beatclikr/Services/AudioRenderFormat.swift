//
//  AudioRenderFormat.swift
//  beatclikr
//

import AVFoundation

struct AudioRenderFormatSnapshot: Equatable {
    let sessionSampleRate: Double
    let outputSampleRate: Double
    let mixerSampleRate: Double
    let playerSampleRate: Double
    let bufferSampleRate: Double?

    init(
        sessionSampleRate: Double,
        outputSampleRate: Double,
        mixerSampleRate: Double,
        playerSampleRate: Double,
        bufferSampleRate: Double? = nil,
    ) {
        self.sessionSampleRate = sessionSampleRate
        self.outputSampleRate = outputSampleRate
        self.mixerSampleRate = mixerSampleRate
        self.playerSampleRate = playerSampleRate
        self.bufferSampleRate = bufferSampleRate
    }

    init(
        session: AVAudioSession = .sharedInstance(),
        engine: AVAudioEngine,
        player: AVAudioPlayerNode,
        buffer: AVAudioPCMBuffer? = nil,
    ) {
        sessionSampleRate = session.sampleRate
        outputSampleRate = engine.outputNode.inputFormat(forBus: 0).sampleRate
        mixerSampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        playerSampleRate = player.outputFormat(forBus: 0).sampleRate
        bufferSampleRate = buffer?.format.sampleRate
    }

    var diagnosticText: String {
        let bufferText = bufferSampleRate.map { String($0) } ?? "none"
        return "session=\(sessionSampleRate) output=\(outputSampleRate) mixer=\(mixerSampleRate) "
            + "player=\(playerSampleRate) buffer=\(bufferText)"
    }
}

enum AudioRenderFormatContract {
    static let sampleRateTolerance = 0.5

    static func ratesMatch(_ first: Double, _ second: Double) -> Bool {
        first > 0 && second > 0 && abs(first - second) <= sampleRateTolerance
    }

    static func standardRenderFormat(outputFormat: AVAudioFormat) -> AVAudioFormat? {
        guard outputFormat.sampleRate > 0, outputFormat.channelCount > 0 else {
            return nil
        }
        return AVAudioFormat(
            standardFormatWithSampleRate: outputFormat.sampleRate,
            channels: min(outputFormat.channelCount, 2),
        )
    }

    static func renderRatesMatch(_ snapshot: AudioRenderFormatSnapshot) -> Bool {
        guard ratesMatch(snapshot.outputSampleRate, snapshot.mixerSampleRate),
              ratesMatch(snapshot.outputSampleRate, snapshot.playerSampleRate)
        else {
            return false
        }
        return snapshot.bufferSampleRate.map {
            ratesMatch(snapshot.outputSampleRate, $0)
        } ?? true
    }

    static func formatChanged(from old: AVAudioFormat, to new: AVAudioFormat) -> Bool {
        !ratesMatch(old.sampleRate, new.sampleRate) || old.channelCount != new.channelCount
    }

    static func effectiveBPM(
        requestedBPM: Double,
        planningSampleRate: Double,
        consumptionSampleRate: Double,
    ) -> Double? {
        guard requestedBPM > 0, planningSampleRate > 0, consumptionSampleRate > 0 else {
            return nil
        }
        return requestedBPM * consumptionSampleRate / planningSampleRate
    }
}
