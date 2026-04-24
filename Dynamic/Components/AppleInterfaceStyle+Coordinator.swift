//
//  AppleInterfaceStyle+Coordinator.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 5/3/19.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import Foundation

extension AppleInterfaceStyle {
    public static let Coordinator = AppleInterfaceStyleCoordinator()
}

/// This class coordinates between scheduler and screen brightness observer.
public class AppleInterfaceStyleCoordinator: NSObject {
    fileprivate override init() { super.init() }
    
    private var appearanceObservation: NSObjectProtocol? {
        didSet {
            if let oldValue {
                NotificationCenter.default.removeObserver(oldValue)
            }
        }
    }
    
    @objc public func toggleOrShowInterface() {
        if preferences.AppleInterfaceStyleSwitchesAutomatically {
            reopen()
        } else {
            AppleInterfaceStyle.toggle()
        }
    }
    
    public func setup() {
        tearDown()
        appearanceObservation = NotificationCenter.default.addObserver(
            forName: .appearanceMonitorDidChange,
            object: nil,
            queue: .main
        ) { _ in
            AppleInterfaceStyle.updateWallpaper()
        }
        guard preferences.scheduled else {
            guard preferences.adjustForBrightness else { return }
            // No need for scheduler, only enable brightness observer
            return ScreenBrightnessObserver.shared.startObserving()
        }
        Connectivity.default.scheduleWhenReconnected()
        Scheduler.shared.schedule(startBrightnessObserverOnFailure: true)
    }
    
    public func tearDown(stopAppearanceObservation: Bool = true) {
        Scheduler.shared.cancel()
        Connectivity.default.stopObserving()
        ScreenBrightnessObserver.shared.stopObserving()
        if stopAppearanceObservation {
            if let appearanceObservation {
                NotificationCenter.default.removeObserver(appearanceObservation)
            }
            self.appearanceObservation = nil
        }
    }
}
