//
//  AppDelegate.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 6/6/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import SwiftUI
import UserNotifications
import Sparkle
#if canImport(LetsMove)
import LetsMove
#endif

@MainActor
final class AppUpdater: ObservableObject {
    static let shared = AppUpdater()
    
    private let controller = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    
    private init() { }
    
    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set {
            guard controller.updater.automaticallyChecksForUpdates != newValue else { return }
            controller.updater.automaticallyChecksForUpdates = newValue
            objectWillChange.send()
        }
    }
    
    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}

@MainActor
final class AppBootstrapper {
    static let shared = AppBootstrapper()
    
    private(set) var hasStarted = false
    
    private init() { }
    
    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        Preferences.setupDefaultsForNewFeatures()
        Shortcut.startObserving()
        if preferences.AppleInterfaceStyleSwitchesAutomatically {
            preferences.scheduleZenithType = .system
        }
        Preferences.startObserving()
        AppleInterfaceStyle.Coordinator.setup()
    }
    
    func stop() {
        hasStarted = false
        Shortcut.stopObserving()
        Preferences.stopObserving()
        AppleInterfaceStyle.Coordinator.tearDown()
        Scheduler.shared.cancel()
    }
    
    func resetForOnboarding() {
        guard let name = Bundle.main.bundleIdentifier else { return }
        preferences.removePersistentDomain(forName: name)
        stop()
        TouchBar.hide()
        AppearanceMonitor.shared.refresh()
        WindowRouter.shared.closeSettingsWindow()
        WindowRouter.shared.showOnboarding()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        #if !DEBUG
        PFMoveToApplicationsFolderIfNecessary()
        #endif
        
        UNUserNotificationCenter.current().delegate = self
        _ = AppUpdater.shared
        AppearanceMonitor.shared.startObserving()
        TouchBar.setup()
        
        if preferences.hasLaunchedBefore {
            AppBootstrapper.shared.startIfNeeded()
        } else {
            TouchBar.hide()
            WindowRouter.shared.showOnboarding()
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        reopen()
        return false
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        WindowRouter.shared.closeOnboarding()
        TouchBar.tearDown()
        AppBootstrapper.shared.stop()
    }
}

@MainActor
func reopen() {
    WindowRouter.shared.reopen()
}
