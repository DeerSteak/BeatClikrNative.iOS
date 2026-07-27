//
//  AudioSessionCoordinator.swift
//  beatclikr
//
//  Created by Ben Funk 7/27/26
//

import AVFoundation
import Foundation
import OSLog

private final class AudioNotificationToken: @unchecked Sendable {
    let value: NSObjectProtocol

    init(_ value: NSObjectProtocol) {
        self.value = value
    }
}

enum AudioLifecycleEvent {
    case interruptionBegan
    case routeDisconnected
    case engineConfigurationChanged
    case mediaServicesLost
    case mediaServicesReset
}

struct AudioSessionPolicy {
    let category: AVAudioSession.Category
    let mode: AVAudioSession.Mode
    let options: AVAudioSession.CategoryOptions

    static let mixedPlayback = AudioSessionPolicy(
        category: .playback,
        mode: .default,
        options: [.mixWithOthers],
    )
}

@MainActor
final class AudioSessionCoordinator {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BeatClikr", category: "AudioSession")
    private let session: AVAudioSession
    private let notificationCenter: NotificationCenter
    private var sessionObservers: [AudioNotificationToken] = []
    private var engineObservers: [AudioNotificationToken] = []

    var onEvent: ((AudioLifecycleEvent) -> Void)?

    init(
        session: AVAudioSession = .sharedInstance(),
        notificationCenter: NotificationCenter = .default,
    ) {
        self.session = session
        self.notificationCenter = notificationCenter
        observeSession()
    }

    deinit {
        for observer in sessionObservers + engineObservers {
            notificationCenter.removeObserver(observer.value)
        }
    }

    func activate() throws {
        let policy = AudioSessionPolicy.mixedPlayback
        try session.setCategory(policy.category, mode: policy.mode, options: policy.options)
        try session.setActive(true)
        logCurrentOutput(reason: "activated")
    }

    func observeEngines(_ engines: [AVAudioEngine]) {
        for observer in engineObservers {
            notificationCenter.removeObserver(observer.value)
        }
        engineObservers = engines.map { engine in
            AudioNotificationToken(notificationCenter.addObserver(
                forName: .AVAudioEngineConfigurationChange,
                object: engine,
                queue: .main,
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.onEvent?(.engineConfigurationChanged)
                }
            })
        }
    }

    private func observeSession() {
        sessionObservers = [
            AudioNotificationToken(notificationCenter.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: session,
                queue: .main,
            ) { [weak self] notification in
                guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                      AVAudioSession.InterruptionType(rawValue: rawType) == .began
                else {
                    return
                }
                Task { @MainActor in
                    self?.onEvent?(.interruptionBegan)
                }
            }),
            AudioNotificationToken(notificationCenter.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: session,
                queue: .main,
            ) { [weak self] notification in
                guard let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                      AVAudioSession.RouteChangeReason(rawValue: rawReason) == .oldDeviceUnavailable
                else {
                    return
                }
                Task { @MainActor in
                    self?.logCurrentOutput(reason: "old output unavailable")
                    self?.onEvent?(.routeDisconnected)
                }
            }),
            AudioNotificationToken(notificationCenter.addObserver(
                forName: AVAudioSession.mediaServicesWereLostNotification,
                object: session,
                queue: .main,
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.onEvent?(.mediaServicesLost)
                }
            }),
            AudioNotificationToken(notificationCenter.addObserver(
                forName: AVAudioSession.mediaServicesWereResetNotification,
                object: session,
                queue: .main,
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.onEvent?(.mediaServicesReset)
                }
            }),
        ]
    }

    private func logCurrentOutput(reason: String) {
        let outputs = session.currentRoute.outputs
            .map { "\($0.portName) [\($0.portType.rawValue)]" }
            .joined(separator: ", ")
        logger.info("Audio route \(reason, privacy: .public): \(outputs, privacy: .public)")
    }
}
