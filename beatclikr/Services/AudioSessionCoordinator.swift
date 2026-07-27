//
//  AudioSessionCoordinator.swift
//  beatclikr
//
//  Created by Ben Funk 7/27/26
//

import AVFoundation
import Foundation

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

@MainActor
final class AudioSessionCoordinator {
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
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
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
}
