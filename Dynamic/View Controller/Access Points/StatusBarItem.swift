//
//  StatusBarItem.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 12/11/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import Combine
import SwiftUI

@MainActor
public final class StatusBarItem {
    public static let only = StatusBarItem()
    private init() { }

    enum Style: Int, CaseIterable {
        case menu
        case rightClick
        case hidden
    }

    private var statusBarItem: NSStatusItem?
    private var compactSettingsPopover: NSPopover?

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
            showMenu()
        } else if preferences.AppleInterfaceStyleSwitchesAutomatically {
            showCompactSettings()
        } else {
            AppleInterfaceStyle.toggle()
        }
    }

    private func showMenu() {
        guard let button = statusBarItem?.button else { return }
        buildMenu().popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: button.bounds.height + 4),
            in: button
        )
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        let usesSystemAutomation = preferences.AppleInterfaceStyleSwitchesAutomatically

        let toggleItem = makeItem(
            title: NSLocalizedString(
                "Menu.toggle",
                value: "Toggle Dark Mode",
                comment: "Action item to toggle in from menu bar"
            ),
            action: #selector(toggleAppearance)
        )
        toggleItem.isEnabled = !usesSystemAutomation
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        menu.addItem(submenuItem(
            title: NSLocalizedString(
                "Menu.automation",
                value: "Automation",
                comment: "Menu section for appearance automation settings"
            ),
            submenu: buildAutomationMenu(usesSystemAutomation: usesSystemAutomation)
        ))
        menu.addItem(submenuItem(
            title: NSLocalizedString(
                "Menu.desktop",
                value: "Desktop",
                comment: "Menu section for desktop wallpaper settings"
            ),
            submenu: buildDesktopMenu()
        ))
        menu.addItem(submenuItem(
            title: NSLocalizedString(
                "Menu.integrations",
                value: "Integrations",
                comment: "Menu section for app integrations"
            ),
            submenu: buildIntegrationsMenu()
        ))
        menu.addItem(.separator())

        let settingsItem = makeItem(
            title: NSLocalizedString(
                "Menu.preferences",
                value: "Settings…",
                comment: "Drop down menu item to show compact settings"
            ),
            action: #selector(showCompactSettingsAction),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = .command
        menu.addItem(settingsItem)

        let quitItem = makeItem(
            title: NSLocalizedString(
                "Menu.quit",
                value: "Quit",
                comment: "Use system translation for quit"
            ),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "Q",
            targetsResponderChain: true
        )
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)
        return menu
    }

    private func buildAutomationMenu(usesSystemAutomation: Bool) -> NSMenu {
        let menu = NSMenu()
        let systemItem = makeItem(
            title: NSLocalizedString(
                "Settings.automation.system.toggle",
                value: "Let macOS switch appearance automatically",
                comment: "System automation toggle."
            ),
            action: #selector(toggleSystemAutomation)
        )
        systemItem.state = usesSystemAutomation ? .on : .off
        menu.addItem(systemItem)
        menu.addItem(.separator())

        let scheduledItem = makeItem(
            title: NSLocalizedString(
                "Settings.automation.schedule.toggle",
                value: "Enable scheduled switching",
                comment: "Schedule toggle."
            ),
            action: #selector(toggleScheduled)
        )
        scheduledItem.state = preferences.scheduled ? .on : .off
        scheduledItem.isEnabled = !usesSystemAutomation
        menu.addItem(scheduledItem)

        let scheduleModeItem = submenuItem(
            title: NSLocalizedString(
                "Settings.automation.schedule.mode",
                value: "Schedule mode",
                comment: "Schedule mode picker."
            ),
            submenu: buildScheduleModeMenu(isEnabled: !usesSystemAutomation && preferences.scheduled)
        )
        scheduleModeItem.isEnabled = !usesSystemAutomation && preferences.scheduled
        menu.addItem(scheduleModeItem)
        return menu
    }

    private func buildScheduleModeMenu(isEnabled: Bool) -> NSMenu {
        let menu = NSMenu()
        for mode in [Zenith.official, .civil, .nautical, .astronomical, .custom, .system] {
            let item = makeItem(
                title: mode.localizedName,
                action: #selector(setScheduleMode(_:))
            )
            item.representedObject = mode.rawValue
            item.state = preferences.scheduleZenithType == mode ? .on : .off
            item.isEnabled = isEnabled
            menu.addItem(item)
        }
        return menu
    }

    private func buildDesktopMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(makeItem(
            title: NSLocalizedString(
                "Settings.desktop.panel.selectLight",
                value: "Choose Light Wallpaper…",
                comment: "Select light wallpaper action."
            ),
            action: #selector(selectLightWallpaper)
        ))
        menu.addItem(makeItem(
            title: NSLocalizedString(
                "Settings.desktop.panel.selectDark",
                value: "Choose Dark Wallpaper…",
                comment: "Select dark wallpaper action."
            ),
            action: #selector(selectDarkWallpaper)
        ))
        let clearItem = makeItem(
            title: NSLocalizedString(
                "Settings.desktop.clear",
                value: "Clear",
                comment: "Clear wallpaper mappings action."
            ),
            action: #selector(clearWallpapers)
        )
        clearItem.isEnabled = preferences.lightDesktopURL != nil || preferences.darkDesktopURL != nil
        menu.addItem(clearItem)
        return menu
    }

    private func buildIntegrationsMenu() -> NSMenu {
        let menu = NSMenu()
        let loginItem = makeItem(
            title: NSLocalizedString(
                "Settings.general.loginItem",
                value: "Launch at login",
                comment: "Launch at login setting label."
            ),
            action: #selector(toggleLaunchAtLogin)
        )
        loginItem.state = preferences.opensAtLogin ? .on : .off
        menu.addItem(loginItem)

        let touchBarItem = makeItem(
            title: NSLocalizedString(
                "Settings.general.touchBar",
                value: "Show Touch Bar toggle",
                comment: "Touch Bar setting label."
            ),
            action: #selector(toggleTouchBar)
        )
        touchBarItem.state = preferences.showToggleInTouchBar ? .on : .off
        menu.addItem(touchBarItem)

        let updateChecksItem = makeItem(
            title: NSLocalizedString(
                "Settings.general.updates.auto",
                value: "Automatically check for updates",
                comment: "Automatic update checks label."
            ),
            action: #selector(toggleAutomaticUpdateChecks)
        )
        updateChecksItem.state = AppUpdater.shared.automaticallyChecksForUpdates ? .on : .off
        menu.addItem(updateChecksItem)
        menu.addItem(makeItem(
            title: NSLocalizedString(
                "Settings.general.updates.manual",
                value: "Check for Updates…",
                comment: "Manual update action."
            ),
            action: #selector(checkForUpdates)
        ))
        return menu
    }

    private func makeItem(
        title: String,
        action: Selector?,
        keyEquivalent: String = "",
        targetsResponderChain: Bool = false
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = targetsResponderChain ? nil : self
        return item
    }

    private func submenuItem(title: String, submenu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    @objc private func toggleAppearance() {
        AppleInterfaceStyle.Coordinator.toggleOrShowInterface()
    }

    @objc private func toggleSystemAutomation() {
        SettingsStore.shared.systemAutomaticAppearance.toggle()
    }

    @objc private func toggleScheduled() {
        SettingsStore.shared.scheduled.toggle()
    }

    @objc private func setScheduleMode(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? Int,
            let mode = Zenith(rawValue: rawValue)
        else { return }
        SettingsStore.shared.scheduleZenithType = mode
    }

    @objc private func selectLightWallpaper() {
        SettingsStore.shared.selectLightWallpaper()
    }

    @objc private func selectDarkWallpaper() {
        SettingsStore.shared.selectDarkWallpaper()
    }

    @objc private func clearWallpapers() {
        SettingsStore.shared.clearWallpapers()
    }

    @objc private func toggleLaunchAtLogin() {
        SettingsStore.shared.opensAtLogin.toggle()
    }

    @objc private func toggleTouchBar() {
        SettingsStore.shared.showToggleInTouchBar.toggle()
    }

    @objc private func toggleAutomaticUpdateChecks() {
        SettingsStore.shared.automaticUpdateChecks.toggle()
    }

    @objc private func checkForUpdates() {
        SettingsStore.shared.checkForUpdates()
    }

    @objc private func showCompactSettingsAction() {
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated {
                self?.showCompactSettings()
            }
        }
    }

    private func showCompactSettings() {
        guard let button = statusBarItem?.button else { return }
        if let compactSettingsPopover, compactSettingsPopover.isShown {
            compactSettingsPopover.close()
            return
        }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 420)
        popover.contentViewController = NSHostingController(
            rootView: CompactSettingsPopoverView(store: SettingsStore.shared)
        )
        compactSettingsPopover = popover
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
    private var appearanceObservation: AnyCancellable?

    public func startObserving() {
        createStatusBarItemIfNecessary()
        statusBarItem?.menu = nil
        appearanceObservation = AppearanceMonitor.shared.$currentStyle
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.statusBarItem?.button?.image = self.statusBarItemImage
                }
            }
    }

    public func stopObserving() {
        appearanceObservation = nil
        compactSettingsPopover?.close()
        compactSettingsPopover = nil
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
