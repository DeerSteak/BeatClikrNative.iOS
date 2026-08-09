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
        let bufferText = bufferSampleRate.map(String.init) ?? "none"
        return "session=\(sessionSampleRate) output=\(outputSampleRate) mixer=\(mixerSampleRate) "
            + "player=\(playerSampleRate) buffer=\(bufferText)"
    }
}

enum AudioRenderFormatContract {
    static let sampleRateTolerance = 0.5

    static func ratesMatch(_ first: Double, _ second: Double) -> Bool {
        first > 0 && second > 0 && abs(first - second) <= sampleRateTolerance
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
