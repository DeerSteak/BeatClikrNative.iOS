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
    
    private var hasFlashlight: Bool
    
    init() {
        //let device = AVCaptureDevice.default(for: .video)
        //hasFlashlight = device?.hasTorch ?? false
        //TODO: check that the device has a flashlight
        hasFlashlight = false
    }
    
    func turnFlashlightOn() {
        if hasFlashlight {
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            if device.torchMode == AVCaptureDevice.TorchMode.on { return }
            do {
                try device.lockForConfiguration()
                try device.setTorchModeOn(level: 1.0)
            } catch {
                print(error)
            }
            device.unlockForConfiguration()
        }
        
    }
    
    func turnFlashlightOff() {
        if hasFlashlight {
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            if device.torchMode == AVCaptureDevice.TorchMode.off { return }
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
