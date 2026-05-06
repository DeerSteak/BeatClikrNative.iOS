//
//  FlashlightService.swift
//  beatclikr
//
//  Created by Ben Funk on 8/6/23.
//

import AVKit
import Foundation

@MainActor
class FlashlightService {
    static let instance = FlashlightService()

    private var hasFlashlight: Bool

    init() {
        let device = AVCaptureDevice.default(for: .video)
        hasFlashlight = device?.hasTorch ?? false
    }

    func turnFlashlightOn() {
        if hasFlashlight {
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            if device.torchMode == .on { return }
            do {
                try device.lockForConfiguration()
                try device.setTorchModeOn(level: 1.0)
                device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }

    func turnFlashlightOff() {
        if hasFlashlight {
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            if device.torchMode == .off { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
}
