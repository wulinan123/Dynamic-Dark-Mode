//
//  AppleInterfaceStyle+NSAppearance.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 6/6/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import Combine
import Foundation

extension Notification.Name {
    static let appearanceMonitorDidChange = Notification.Name("AppearanceMonitor.didChange")
}

@MainActor
final class AppearanceMonitor: ObservableObject {
    static let shared = AppearanceMonitor()
    
    @Published private(set) var currentStyle: AppleInterfaceStyle = AppleInterfaceStyle.systemCurrent
    
    private var isObserving = false
    private var distributedObserver: NSObjectProtocol?
    private var appObserver: NSObjectProtocol?
    
    private init() { }
    
    func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        distributedObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
        appObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
        refresh()
    }
    
    func refresh() {
        let resolved = AppleInterfaceStyle.systemCurrent
        if currentStyle != resolved {
            currentStyle = resolved
        }
        NotificationCenter.default.post(name: .appearanceMonitorDidChange, object: resolved)
    }
}

extension AppleInterfaceStyle {
    static var systemCurrent: AppleInterfaceStyle {
        SLSGetAppearanceThemeLegacy() ? .darkAqua : .aqua
    }
    
    static var current: AppleInterfaceStyle {
        AppearanceMonitor.shared.currentStyle
    }
    
    static var isDark: Bool {
        current == .darkAqua
    }
}
