//
//  StatusBarItem.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 12/11/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import Combine

public final class StatusBarItem {
    public static let only = StatusBarItem()
    private init() { }
    
    enum Style: Int, CaseIterable {
        case menu
        case rightClick
        case hidden
    }
    
    private var statusBarItem: NSStatusItem?
    
    private var statusBarItemImage: NSImage {
        let symbolName = AppearanceMonitor.shared.currentStyle == .darkAqua
            ? "moon.fill"
            : "sun.max.fill"
        let image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: nil
        ) ?? NSImage()
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }
    
    private func createStatusBarItemIfNecessary() {
        guard statusBarItem == nil else { return }
        statusBarItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )
        statusBarItem?.button?.image = statusBarItemImage
        statusBarItem?.button?.imageScaling = .scaleProportionallyDown
        statusBarItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusBarItem?.button?.action = #selector(handleEvent)
        statusBarItem?.button?.target = self
    }
    
    @objc private func handleEvent() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            WindowRouter.shared.showSettings()
        } else {
            AppleInterfaceStyle.Coordinator.toggleOrShowInterface()
        }
    }
    
    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        let toggleItem = NSMenuItem(
            title: NSLocalizedString(
                "Menu.toggle",
                value: "Toggle Dark Mode",
                comment: "Action item to toggle in from menu bar"),
            action: #selector(handleEvent),
            keyEquivalent: ""
        )
        toggleItem.target = self
        if #available(macOS 10.15, *) {
            toggleItem.bindEnabledToNotAppleInterfaceStyleSwitchesAutomatically()
        }
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        let preferencesItem = NSMenuItem(
            title: NSLocalizedString(
                "Menu.preferences",
                value: "Preferences…",
                comment: "Drop down menu item to show preferences"),
            action: #selector(WindowRouter.showSettingsAction),
            keyEquivalent: ","
        )
        preferencesItem.keyEquivalentModifierMask = .command
        preferencesItem.target = WindowRouter.shared
        menu.addItem(preferencesItem)
        let quitItem = NSMenuItem(
            title: NSLocalizedString(
                "Menu.quit",
                value: "Quit",
                comment: "Use system translation for quit"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "Q"
        )
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)
        return menu
    }
    
    private var appearanceObservation: AnyCancellable?
    private var settingsStyleObservation: NSKeyValueObservation?
    
    public func startObserving() {
        appearanceObservation = AppearanceMonitor.shared.$currentStyle
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.statusBarItem?.button?.image = self.statusBarItemImage
            }
        settingsStyleObservation = preferences.observe(
            \.rawSettingsStyle, options: [.initial, .new]
        ) { [weak self] _, change in
            guard let self = self else { return }
            switch preferences.settingsStyle {
            case .menu:
                self.createStatusBarItemIfNecessary()
                self.statusBarItem?.menu = self.buildMenu()
            case .rightClick:
                self.createStatusBarItemIfNecessary()
                self.statusBarItem?.menu = nil
            case .hidden:
                guard let statusBarItem = self.statusBarItem else { return }
                NSStatusBar.system.removeStatusItem(statusBarItem)
                self.statusBarItem = nil
            }
        }
    }
    
    public func stopObserving() {
        appearanceObservation = nil
        settingsStyleObservation?.invalidate()
        settingsStyleObservation = nil
    }
}

extension StatusBarItem.Style {
    var localizedName: String {
        switch self {
        case .menu:
            return NSLocalizedString(
                "Settings.menuBarStyle.menu",
                value: "Show Menu",
                comment: "Menu bar left click shows a menu."
            )
        case .rightClick:
            return NSLocalizedString(
                "Settings.menuBarStyle.toggle",
                value: "Left Click Toggles",
                comment: "Menu bar left click toggles appearance and right click opens settings."
            )
        case .hidden:
            return NSLocalizedString(
                "Settings.menuBarStyle.hidden",
                value: "Hidden",
                comment: "Menu bar item is hidden."
            )
        }
    }
}
