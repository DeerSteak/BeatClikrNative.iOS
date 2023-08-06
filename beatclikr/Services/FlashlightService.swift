//
//  FlashlightHelper.swift
//  beatclikr
//
//  Created by Ben Funk on 8/6/23.
//

import Foundation
import AVKit

class FlashlightService {
    static var instance = FlashlightService()
    
    func checkFlashlight() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video) else {
            return false
        }
        return device.hasTorch
    }
    
    func toggleFlashlight() {
        if (checkFlashlight()) {
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            do {
                try device.lockForConfiguration()
            } catch {
                print(error)
            }
            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print(error)
                }
            }
            device.unlockForConfiguration()
        }
    }
    
    func turnFlashlightOff() {
        if (checkFlashlight()) {
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                do {
                    try device.lockForConfiguration()
                } catch {
                    print(error)
                }
                device.torchMode = AVCaptureDevice.TorchMode.off
                device.unlockForConfiguration()
            }
        }
    }
}
