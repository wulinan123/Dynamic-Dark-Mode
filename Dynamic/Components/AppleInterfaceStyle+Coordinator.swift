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

/// This class coordinates scheduler updates with appearance changes.
public class AppleInterfaceStyleCoordinator: NSObject {
    fileprivate override init() { super.init() }
    
    private var appearanceObservation: NSObjectProtocol? {
        didSet {
            if let oldValue {
                NotificationCenter.default.removeObserver(oldValue)
            }
        }
    }
    
    @MainActor
    @objc public func toggleOrShowInterface() {
        if preferences.AppleInterfaceStyleSwitchesAutomatically {
            preferences.AppleInterfaceStyleSwitchesAutomatically = false
            if preferences.scheduleZenithType == .system {
                preferences.scheduleZenithType = .official
            }
        }
        AppleInterfaceStyle.toggle()
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
        guard preferences.scheduled else { return }
        Connectivity.default.scheduleWhenReconnected()
        Scheduler.shared.schedule()
    }
    
    public func tearDown(stopAppearanceObservation: Bool = true) {
        Scheduler.shared.cancel()
        Connectivity.default.stopObserving()
        if stopAppearanceObservation {
            if let appearanceObservation {
                NotificationCenter.default.removeObserver(appearanceObservation)
            }
            self.appearanceObservation = nil
        }
    }
}
