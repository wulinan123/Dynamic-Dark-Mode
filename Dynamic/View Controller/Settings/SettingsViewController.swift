//
//  SettingsViewController.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 6/9/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import SwiftUI

@main
struct DynamicDarkModeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsRootView()
        }
    }
}

final class SettingsViewController: NSObject {
    @MainActor
    @objc public static func show() {
        WindowRouter.shared.showSettings()
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private var observers: [NSObjectProtocol] = []

    private init() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.objectWillChange.send()
            }
        })
        observers.append(center.addObserver(
            forName: .appearanceMonitorDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.objectWillChange.send()
            }
        })
        observers.append(center.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.objectWillChange.send()
            }
        })
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    var currentAppearanceLabel: String {
        switch AppearanceMonitor.shared.currentStyle {
        case .aqua:
            return NSLocalizedString(
                "Settings.currentAppearance.light",
                value: "Light appearance is active",
                comment: "Current appearance label."
            )
        case .darkAqua:
            return NSLocalizedString(
                "Settings.currentAppearance.dark",
                value: "Dark appearance is active",
                comment: "Current appearance label."
            )
        }
    }

    var statusBarStyle: StatusBarItem.Style {
        get { preferences.settingsStyle }
        set {
            preferences.settingsStyle = newValue
            objectWillChange.send()
        }
    }

    var systemAutomaticAppearance: Bool {
        get { preferences.AppleInterfaceStyleSwitchesAutomatically }
        set {
            preferences.AppleInterfaceStyleSwitchesAutomatically = newValue
            objectWillChange.send()
        }
    }

    var scheduled: Bool {
        get { preferences.scheduled }
        set {
            preferences.scheduled = newValue
            objectWillChange.send()
        }
    }

    var scheduleZenithType: Zenith {
        get { preferences.scheduleZenithType }
        set {
            preferences.scheduleZenithType = newValue
            objectWillChange.send()
        }
    }

    var scheduleStart: Date {
        get { preferences.scheduleStart }
        set {
            preferences.scheduleStart = newValue
            objectWillChange.send()
        }
    }

    var scheduleEnd: Date {
        get { preferences.scheduleEnd }
        set {
            preferences.scheduleEnd = newValue
            objectWillChange.send()
        }
    }

    var adjustForBrightness: Bool {
        get { preferences.adjustForBrightness }
        set {
            preferences.adjustForBrightness = newValue
            objectWillChange.send()
        }
    }

    var disableAdjustForBrightnessWhenScheduledDarkModeOn: Bool {
        get { preferences.disableAdjustForBrightnessWhenScheduledDarkModeOn }
        set {
            preferences.disableAdjustForBrightnessWhenScheduledDarkModeOn = newValue
            objectWillChange.send()
        }
    }

    var brightnessThreshold: Double {
        get { Double(preferences.brightnessThreshold) }
        set {
            preferences.brightnessThreshold = Float(newValue)
            objectWillChange.send()
        }
    }

    var showToggleInTouchBar: Bool {
        get { preferences.showToggleInTouchBar }
        set {
            preferences.showToggleInTouchBar = newValue
            objectWillChange.send()
        }
    }

    var opensAtLogin: Bool {
        get { preferences.opensAtLogin }
        set {
            preferences.opensAtLogin = newValue
            objectWillChange.send()
        }
    }

    var lightDesktopURL: URL? {
        get { preferences.lightDesktopURL }
        set {
            preferences.lightDesktopURL = newValue
            AppleInterfaceStyle.updateWallpaper()
            objectWillChange.send()
        }
    }

    var darkDesktopURL: URL? {
        get { preferences.darkDesktopURL }
        set {
            preferences.darkDesktopURL = newValue
            AppleInterfaceStyle.updateWallpaper()
            objectWillChange.send()
        }
    }

    var locationSummary: String {
        if let placemark = preferences.placemark, !placemark.isEmpty {
            return placemark
        }
        if let location = preferences.location {
            return String(
                format: "%.4f, %.4f",
                location.coordinate.latitude,
                location.coordinate.longitude
            )
        }
        return NSLocalizedString(
            "Settings.location.unknown",
            value: "No location cached yet",
            comment: "No cached location string."
        )
    }

    var automaticUpdateChecks: Bool {
        get { AppUpdater.shared.automaticallyChecksForUpdates }
        set {
            AppUpdater.shared.automaticallyChecksForUpdates = newValue
            objectWillChange.send()
        }
    }

    var usesSystemAutomation: Bool {
        systemAutomaticAppearance
    }

    func selectLightWallpaper() {
        DynamicDesktopSettingsViewController.selectImage { [weak self] url in
            guard let self else { return }
            var selection = DesktopWallpaperSelection(
                lightURL: self.lightDesktopURL,
                darkURL: self.darkDesktopURL
            )
            selection.set(url, for: .light)
            self.lightDesktopURL = selection.lightURL
        }
    }

    func selectDarkWallpaper() {
        DynamicDesktopSettingsViewController.selectImage { [weak self] url in
            guard let self else { return }
            var selection = DesktopWallpaperSelection(
                lightURL: self.lightDesktopURL,
                darkURL: self.darkDesktopURL
            )
            selection.set(url, for: .dark)
            self.darkDesktopURL = selection.darkURL
        }
    }

    func clearWallpapers() {
        var selection = DesktopWallpaperSelection(
            lightURL: lightDesktopURL,
            darkURL: darkDesktopURL
        )
        selection.clear()
        lightDesktopURL = selection.lightURL
        darkDesktopURL = selection.darkURL
    }

    func checkForUpdates() {
        AppUpdater.shared.checkForUpdates()
    }

    func openCredits() {
        guard let url = Bundle.main.url(forResource: "Credits", withExtension: "html") else { return }
        NSWorkspace.shared.open(url)
    }

    func openProject() {
        openURL("https://github.com/ApolloZhu/Dynamic-Dark-Mode")
    }

    func openLicense() {
        openURL("https://github.com/ApolloZhu/Dynamic-Dark-Mode/blob/master/LICENSE")
    }

    func openIssues() {
        openURL("https://github.com/ApolloZhu/Dynamic-Dark-Mode/issues/new")
    }

    func resetSetup() {
        AppBootstrapper.shared.resetForOnboarding()
    }

    func quit() {
        NSApp.terminate(nil)
    }
}

struct SettingsRootView: View {
    @ObservedObject private var store = SettingsStore.shared

    var body: some View {
        LegacySettingsPanel(store: store)
            .frame(minWidth: 790, idealWidth: 790, minHeight: 760, idealHeight: 760)
        .background(
            WindowAccessor(identifier: WindowRouter.settingsWindowID) { window in
                window.toolbarStyle = .preference
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
                window.backgroundColor = .clear
                window.isOpaque = false
                window.setContentSize(NSSize(width: 790, height: 760))
            }
        )
    }
}

private struct LegacySettingsPanel: View {
    @ObservedObject var store: SettingsStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPresentingDesktopPanel = false

    private let zenithModes: [Zenith] = [.official, .civil, .nautical, .astronomical, .custom, .system]

    var body: some View {
        ZStack {
            LegacyLiquidBackground()

            VStack(alignment: .leading, spacing: 20) {
                header

                VStack(alignment: .leading, spacing: 12) {
                    LegacySettingsRow(
                        NSLocalizedString(
                            "Settings.general.shortcut.title",
                            value: "Shortcut",
                            comment: "Shortcut section title."
                        )
                    ) {
                        ShortcutRecorderView()
                            .frame(height: 36)
                    }

                    LegacySettingsRow(
                        NSLocalizedString(
                            "Settings.legacy.automation",
                            value: "Automation",
                            comment: "Legacy automation row title."
                        )
                    ) {
                        Toggle(
                            NSLocalizedString(
                                "Settings.automation.brightness.toggle",
                                value: "Adjust appearance based on brightness",
                                comment: "Brightness toggle."
                            ),
                            isOn: Binding(
                                get: { store.adjustForBrightness },
                                set: { store.adjustForBrightness = $0 }
                            )
                        )
                        .disabled(store.usesSystemAutomation)
                    }

                    LegacySettingsRow(
                        NSLocalizedString(
                            "Settings.legacy.threshold",
                            value: "Threshold",
                            comment: "Brightness threshold row title."
                        )
                    ) {
                        HStack(spacing: 18) {
                            Image(systemName: "moon.fill")
                                .font(.title2)
                            Slider(
                                value: Binding(
                                    get: { store.brightnessThreshold },
                                    set: { store.brightnessThreshold = $0 }
                                ),
                                in: 0...1
                            )
                            Image(systemName: "sun.max")
                                .font(.title2)
                        }
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.primary)
                        .disabled(store.usesSystemAutomation || !store.adjustForBrightness)
                    }

                    LegacySettingsRow("") {
                        Toggle(
                            NSLocalizedString(
                                "Settings.automation.brightness.disableAtNight",
                                value: "Pause brightness switching during scheduled dark mode",
                                comment: "Disable brightness switching during night schedule."
                            ),
                            isOn: Binding(
                                get: { store.disableAdjustForBrightnessWhenScheduledDarkModeOn },
                                set: { store.disableAdjustForBrightnessWhenScheduledDarkModeOn = $0 }
                            )
                        )
                        .disabled(store.usesSystemAutomation || !store.adjustForBrightness || !store.scheduled)
                    }

                    LegacySettingsRow(
                        NSLocalizedString(
                            "Settings.automation.schedule.title",
                            value: "Schedule",
                            comment: "Schedule section title."
                        )
                    ) {
                        HStack(spacing: 12) {
                            Toggle(
                                NSLocalizedString(
                                    "Settings.automation.schedule.toggle",
                                    value: "Enable scheduled switching",
                                    comment: "Schedule toggle."
                                ),
                                isOn: Binding(
                                    get: { store.scheduled },
                                    set: { store.scheduled = $0 }
                                )
                            )
                            .disabled(store.usesSystemAutomation)

                            Picker("", selection: Binding(
                                get: { store.scheduleZenithType },
                                set: { store.scheduleZenithType = $0 }
                            )) {
                                ForEach(zenithModes, id: \.rawValue) { mode in
                                    Text(mode.localizedName).tag(mode)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 220)
                            .disabled(store.usesSystemAutomation || !store.scheduled)
                        }
                    }

                    LegacySettingsRow("") {
                        HStack(spacing: 12) {
                            Text(NSLocalizedString(
                                "Settings.automation.schedule.from",
                                value: "From",
                                comment: "Schedule start label."
                            ))
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { store.scheduleStart },
                                    set: { store.scheduleStart = $0 }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .frame(width: 150)

                            Text(NSLocalizedString(
                                "Settings.automation.schedule.to",
                                value: "To",
                                comment: "Schedule end label."
                            ))
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { store.scheduleEnd },
                                    set: { store.scheduleEnd = $0 }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .frame(width: 150)
                        }
                        .disabled(store.usesSystemAutomation || !store.scheduled || store.scheduleZenithType != .custom)
                    }

                    LegacySettingsRow(
                        NSLocalizedString(
                            "Settings.general.menuBar.title",
                            value: "Menu Bar",
                            comment: "Menu bar section title."
                        )
                    ) {
                        Picker("", selection: Binding(
                            get: { store.statusBarStyle },
                            set: { store.statusBarStyle = $0 }
                        )) {
                            ForEach(StatusBarItem.Style.allCases, id: \.rawValue) { style in
                                Text(style.localizedName).tag(style)
                            }
                        }
                        .labelsHidden()
                    }

                    LegacySettingsRow(
                        NSLocalizedString(
                            "Settings.legacy.touchBar",
                            value: "Touch Bar",
                            comment: "Touch Bar row title."
                        )
                    ) {
                        Toggle(
                            NSLocalizedString(
                                "Settings.general.touchBar",
                                value: "Show Touch Bar toggle",
                                comment: "Touch Bar setting label."
                            ),
                            isOn: Binding(
                                get: { store.showToggleInTouchBar },
                                set: { store.showToggleInTouchBar = $0 }
                            )
                        )
                    }

                    LegacySettingsRow(
                        NSLocalizedString(
                            "Settings.desktop.title",
                            value: "Desktop",
                            comment: "Desktop tab heading."
                        )
                    ) {
                        Button(
                            NSLocalizedString(
                                "Settings.desktop.manage",
                                value: "Manage Wallpapers...",
                                comment: "Manage wallpaper mappings action."
                            )
                        ) {
                            isPresentingDesktopPanel = true
                        }
                        .frame(maxWidth: .infinity)
                    }

                    LegacySettingsRow(
                        NSLocalizedString(
                            "Settings.legacy.other",
                            value: "Other",
                            comment: "Other row title."
                        )
                    ) {
                        Toggle(
                            NSLocalizedString(
                                "Settings.general.loginItem",
                                value: "Launch at login",
                                comment: "Launch at login setting label."
                            ),
                            isOn: Binding(
                                get: { store.opensAtLogin },
                                set: { store.opensAtLogin = $0 }
                            )
                        )
                    }

                    LegacySettingsRow("") {
                        HStack(spacing: 12) {
                            Toggle(
                                NSLocalizedString(
                                    "Settings.general.updates.auto",
                                    value: "Automatically check for updates",
                                    comment: "Automatic update checks label."
                                ),
                                isOn: Binding(
                                    get: { store.automaticUpdateChecks },
                                    set: { store.automaticUpdateChecks = $0 }
                                )
                            )
                            Button(
                                NSLocalizedString(
                                    "Settings.general.updates.manual",
                                    value: "Check for Updates...",
                                    comment: "Manual update action."
                                ),
                                action: store.checkForUpdates
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                Spacer(minLength: 8)

                footer
            }
            .padding(.horizontal, 40)
            .padding(.top, 42)
            .padding(.bottom, 30)
        }
        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.92) : Color.primary)
        .sheet(isPresented: $isPresentingDesktopPanel) {
            DynamicDesktopPanelView(store: store)
                .frame(width: 640, height: 460)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            Text(NSLocalizedString(
                "Settings.legacy.title",
                value: "Automatic Dark Mode Settings",
                comment: "Legacy inspired settings window title."
            ))
            .font(.system(size: 36, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            Spacer()

            Button {
                store.openProject()
            } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(NSLocalizedString(
                "Settings.legacy.help",
                value: "Open project help",
                comment: "Help button tooltip."
            ))
        }
    }

    private var footer: some View {
        HStack {
            Button {
                store.quit()
            } label: {
                Text(NSLocalizedString(
                    "Settings.about.quit",
                    value: "Quit",
                    comment: "Quit action."
                ) + " (Cmd Q)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .keyboardShortcut("q", modifiers: .command)

            Spacer()

            Button(
                NSLocalizedString(
                    "Settings.about.reset",
                    value: "Run Setup Again",
                    comment: "Reset setup action."
                ),
                action: store.resetSetup
            )
            .controlSize(.large)

            Button(
                NSLocalizedString(
                    "Settings.legacy.done",
                    value: "Done",
                    comment: "Close settings window action."
                )
            ) {
                NSApp.keyWindow?.close()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
    }
}

private struct LegacyLiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.regularMaterial)

            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.08, green: 0.10, blue: 0.13).opacity(0.92),
                        Color(red: 0.17, green: 0.15, blue: 0.28).opacity(0.86),
                        Color(red: 0.08, green: 0.12, blue: 0.12).opacity(0.9)
                    ]
                    : [
                        Color(red: 0.88, green: 0.93, blue: 1.0).opacity(0.92),
                        Color(red: 0.98, green: 0.95, blue: 0.88).opacity(0.72),
                        Color(red: 0.86, green: 0.96, blue: 0.91).opacity(0.82)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.18 : 0.12))
                .frame(width: 420, height: 420)
                .blur(radius: 70)
                .offset(x: 290, y: -280)

            Circle()
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.14 : 0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: -340, y: 320)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.32), lineWidth: 1)
                .padding(1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .ignoresSafeArea()
    }
}

private struct LegacySettingsRow<Content: View>: View {
    private let title: String
    @ViewBuilder private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 22) {
            Text(title)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .frame(width: 146, alignment: .trailing)
                .foregroundStyle(.primary)

            content
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .controlSize(.large)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 38)
    }
}

struct GeneralSettingsTab: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        SettingsPaneScroll(title: NSLocalizedString(
            "Settings.general.title",
            value: "General",
            comment: "General tab heading."
        ), subtitle: store.currentAppearanceLabel) {
            SettingsCard(
                title: NSLocalizedString(
                    "Settings.general.menuBar.title",
                    value: "Menu Bar",
                    comment: "Menu bar section title."
                ),
                subtitle: NSLocalizedString(
                    "Settings.general.menuBar.subtitle",
                    value: "Choose how the status item behaves when you click it.",
                    comment: "Menu bar section subtitle."
                )
            ) {
                Picker(
                    NSLocalizedString(
                        "Settings.general.menuBar.mode",
                        value: "Interaction",
                        comment: "Menu bar interaction label."
                    ),
                    selection: Binding(
                        get: { store.statusBarStyle },
                        set: { store.statusBarStyle = $0 }
                    )
                ) {
                    ForEach(StatusBarItem.Style.allCases, id: \.rawValue) { style in
                        Text(style.localizedName).tag(style)
                    }
                }
                .pickerStyle(.menu)
            }

            SettingsCard(
                title: NSLocalizedString(
                    "Settings.general.shortcut.title",
                    value: "Shortcut",
                    comment: "Shortcut section title."
                ),
                subtitle: NSLocalizedString(
                    "Settings.general.shortcut.subtitle",
                    value: "Keep a dedicated shortcut for manual switching when system automation is off.",
                    comment: "Shortcut section subtitle."
                )
            ) {
                HStack(alignment: .center, spacing: 16) {
                    ShortcutRecorderView()
                        .frame(width: 220, height: 34)
                    Text(store.usesSystemAutomation
                        ? NSLocalizedString(
                            "Settings.general.shortcut.disabled",
                            value: "Disabled while system appearance automation is enabled.",
                            comment: "Shortcut disabled note."
                        )
                        : NSLocalizedString(
                            "Settings.general.shortcut.enabled",
                            value: "Available for instant manual switching.",
                            comment: "Shortcut enabled note."
                        )
                    )
                    .foregroundStyle(.secondary)
                }
                .disabled(store.usesSystemAutomation)
            }

            SettingsCard(
                title: NSLocalizedString(
                    "Settings.general.integrations.title",
                    value: "Integrations",
                    comment: "Integrations section title."
                ),
                subtitle: NSLocalizedString(
                    "Settings.general.integrations.subtitle",
                    value: "Control startup behavior, Touch Bar access, and update checks.",
                    comment: "Integrations section subtitle."
                )
            ) {
                Toggle(
                    NSLocalizedString(
                        "Settings.general.touchBar",
                        value: "Show Touch Bar toggle",
                        comment: "Touch Bar setting label."
                    ),
                    isOn: Binding(
                        get: { store.showToggleInTouchBar },
                        set: { store.showToggleInTouchBar = $0 }
                    )
                )
                Toggle(
                    NSLocalizedString(
                        "Settings.general.loginItem",
                        value: "Launch at login",
                        comment: "Launch at login setting label."
                    ),
                    isOn: Binding(
                        get: { store.opensAtLogin },
                        set: { store.opensAtLogin = $0 }
                    )
                )
                Toggle(
                    NSLocalizedString(
                        "Settings.general.updates.auto",
                        value: "Automatically check for updates",
                        comment: "Automatic update checks label."
                    ),
                    isOn: Binding(
                        get: { store.automaticUpdateChecks },
                        set: { store.automaticUpdateChecks = $0 }
                    )
                )
                Button(
                    NSLocalizedString(
                        "Settings.general.updates.manual",
                        value: "Check for Updates…",
                        comment: "Manual update action."
                    ),
                    action: store.checkForUpdates
                )
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct AutomationSettingsTab: View {
    @ObservedObject var store: SettingsStore

    private let zenithModes: [Zenith] = [.official, .civil, .nautical, .astronomical, .custom, .system]

    var body: some View {
        SettingsPaneScroll(title: NSLocalizedString(
            "Settings.automation.title",
            value: "Automation",
            comment: "Automation tab heading."
        ), subtitle: NSLocalizedString(
            "Settings.automation.subtitle",
            value: "Blend system automation, schedules, brightness, and daylight-based timing.",
            comment: "Automation tab subtitle."
        )) {
            SettingsCard(
                title: NSLocalizedString(
                    "Settings.automation.system.title",
                    value: "System Appearance Automation",
                    comment: "System automation section title."
                ),
                subtitle: NSLocalizedString(
                    "Settings.automation.system.subtitle",
                    value: "When enabled, macOS controls the appearance schedule and manual toggles open Settings instead.",
                    comment: "System automation section subtitle."
                )
            ) {
                Toggle(
                    NSLocalizedString(
                        "Settings.automation.system.toggle",
                        value: "Let macOS switch appearance automatically",
                        comment: "System automation toggle."
                    ),
                    isOn: Binding(
                        get: { store.systemAutomaticAppearance },
                        set: { store.systemAutomaticAppearance = $0 }
                    )
                )
            }

            SettingsCard(
                title: NSLocalizedString(
                    "Settings.automation.schedule.title",
                    value: "Schedule",
                    comment: "Schedule section title."
                ),
                subtitle: NSLocalizedString(
                    "Settings.automation.schedule.subtitle",
                    value: "Use daylight presets or a custom range when system automation is off.",
                    comment: "Schedule section subtitle."
                )
            ) {
                Toggle(
                    NSLocalizedString(
                        "Settings.automation.schedule.toggle",
                        value: "Enable scheduled switching",
                        comment: "Schedule toggle."
                    ),
                    isOn: Binding(
                        get: { store.scheduled },
                        set: { store.scheduled = $0 }
                    )
                )
                .disabled(store.usesSystemAutomation)

                Picker(
                    NSLocalizedString(
                        "Settings.automation.schedule.mode",
                        value: "Schedule mode",
                        comment: "Schedule mode picker."
                    ),
                    selection: Binding(
                        get: { store.scheduleZenithType },
                        set: { store.scheduleZenithType = $0 }
                    )
                ) {
                    ForEach(zenithModes, id: \.rawValue) { mode in
                        Text(mode.localizedName).tag(mode)
                    }
                }
                .disabled(store.usesSystemAutomation || !store.scheduled)

                if store.scheduleZenithType == .custom && !store.usesSystemAutomation && store.scheduled {
                    HStack(spacing: 16) {
                        DatePicker(
                            NSLocalizedString(
                                "Settings.automation.schedule.from",
                                value: "From",
                                comment: "Schedule start label."
                            ),
                            selection: Binding(
                                get: { store.scheduleStart },
                                set: { store.scheduleStart = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        DatePicker(
                            NSLocalizedString(
                                "Settings.automation.schedule.to",
                                value: "To",
                                comment: "Schedule end label."
                            ),
                            selection: Binding(
                                get: { store.scheduleEnd },
                                set: { store.scheduleEnd = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                if store.scheduleZenithType.hasSunriseSunsetTime {
                    LabeledContent(
                        NSLocalizedString(
                            "Settings.automation.location",
                            value: "Last known location",
                            comment: "Location summary label."
                        ),
                        value: store.locationSummary
                    )
                    .foregroundStyle(.secondary)
                }
            }

            SettingsCard(
                title: NSLocalizedString(
                    "Settings.automation.brightness.title",
                    value: "Brightness",
                    comment: "Brightness section title."
                ),
                subtitle: NSLocalizedString(
                    "Settings.automation.brightness.subtitle",
                    value: "React to ambient changes when your display supports automatic brightness updates.",
                    comment: "Brightness section subtitle."
                )
            ) {
                Toggle(
                    NSLocalizedString(
                        "Settings.automation.brightness.toggle",
                        value: "Adjust appearance based on brightness",
                        comment: "Brightness toggle."
                    ),
                    isOn: Binding(
                        get: { store.adjustForBrightness },
                        set: { store.adjustForBrightness = $0 }
                    )
                )
                .disabled(store.usesSystemAutomation)

                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        String(
                            format: NSLocalizedString(
                                "Settings.automation.brightness.threshold",
                                value: "Threshold: %.0f%%",
                                comment: "Brightness threshold label."
                            ),
                            store.brightnessThreshold * 100
                        )
                    )
                    Slider(
                        value: Binding(
                            get: { store.brightnessThreshold },
                            set: { store.brightnessThreshold = $0 }
                        ),
                        in: 0...1
                    )
                }
                .disabled(store.usesSystemAutomation || !store.adjustForBrightness)

                Toggle(
                    NSLocalizedString(
                        "Settings.automation.brightness.disableAtNight",
                        value: "Pause brightness switching during scheduled dark mode",
                        comment: "Disable brightness switching during night schedule."
                    ),
                    isOn: Binding(
                        get: { store.disableAdjustForBrightnessWhenScheduledDarkModeOn },
                        set: { store.disableAdjustForBrightnessWhenScheduledDarkModeOn = $0 }
                    )
                )
                .disabled(store.usesSystemAutomation || !store.adjustForBrightness || !store.scheduled)
            }
        }
    }
}

struct DesktopSettingsTab: View {
    @ObservedObject var store: SettingsStore
    @State private var isPresentingPanel = false

    var body: some View {
        SettingsPaneScroll(title: NSLocalizedString(
            "Settings.desktop.title",
            value: "Desktop",
            comment: "Desktop tab heading."
        ), subtitle: NSLocalizedString(
            "Settings.desktop.subtitle",
            value: "Mirror the current appearance with optional light and dark wallpapers.",
            comment: "Desktop tab subtitle."
        )) {
            SettingsCard(
                title: NSLocalizedString(
                    "Settings.desktop.preview.title",
                    value: "Current Wallpaper Mapping",
                    comment: "Desktop mapping section title."
                ),
                subtitle: NSLocalizedString(
                    "Settings.desktop.preview.subtitle",
                    value: "Preview the assets used when the system switches appearance.",
                    comment: "Desktop mapping section subtitle."
                )
            ) {
                DesktopPreviewRow(
                    title: NSLocalizedString(
                        "Settings.desktop.preview.light",
                        value: "Light appearance",
                        comment: "Light wallpaper preview title."
                    ),
                    url: store.lightDesktopURL,
                    symbolName: "sun.max.fill"
                )
                DesktopPreviewRow(
                    title: NSLocalizedString(
                        "Settings.desktop.preview.dark",
                        value: "Dark appearance",
                        comment: "Dark wallpaper preview title."
                    ),
                    url: store.darkDesktopURL,
                    symbolName: "moon.fill"
                )
                HStack {
                    Button(
                        NSLocalizedString(
                            "Settings.desktop.manage",
                            value: "Manage Wallpapers…",
                            comment: "Manage wallpaper mappings action."
                        )
                    ) {
                        isPresentingPanel = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if store.lightDesktopURL != nil || store.darkDesktopURL != nil {
                        Button(
                            NSLocalizedString(
                                "Settings.desktop.clear",
                                value: "Clear",
                                comment: "Clear wallpaper mappings action."
                            ),
                            action: store.clearWallpapers
                        )
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingPanel) {
            DynamicDesktopPanelView(store: store)
                .frame(width: 640, height: 460)
        }
    }
}

struct AboutSettingsTab: View {
    @ObservedObject var store: SettingsStore

    private var versionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    var body: some View {
        SettingsPaneScroll(title: NSLocalizedString(
            "Settings.about.title",
            value: "About",
            comment: "About tab heading."
        ), subtitle: NSLocalizedString(
            "Settings.about.subtitle",
            value: "Project information, credits, feedback, and maintenance actions.",
            comment: "About tab subtitle."
        )) {
            SettingsCard(
                title: NSLocalizedString(
                    "Settings.about.app.title",
                    value: "Dynamic Dark Mode",
                    comment: "About app card title."
                ),
                subtitle: String(
                    format: NSLocalizedString(
                        "Settings.about.app.subtitle",
                        value: "Version %@",
                        comment: "Version subtitle."
                    ),
                    versionString
                )
            ) {
                HStack(spacing: 12) {
                    Button("Credits", action: store.openCredits)
                    Button("Project", action: store.openProject)
                    Button("License", action: store.openLicense)
                    Button(
                        NSLocalizedString(
                            "Settings.about.feedback",
                            value: "Send Feedback",
                            comment: "Feedback action."
                        ),
                        action: store.openIssues
                    )
                }
                .buttonStyle(.bordered)
            }

            SettingsCard(
                title: NSLocalizedString(
                    "Settings.about.maintenance.title",
                    value: "Maintenance",
                    comment: "Maintenance section title."
                ),
                subtitle: NSLocalizedString(
                    "Settings.about.maintenance.subtitle",
                    value: "Reset onboarding or quit the app without leaving Settings.",
                    comment: "Maintenance section subtitle."
                )
            ) {
                HStack(spacing: 12) {
                    Button(
                        NSLocalizedString(
                            "Settings.about.reset",
                            value: "Run Setup Again",
                            comment: "Reset setup action."
                        ),
                        action: store.resetSetup
                    )
                    .buttonStyle(.borderedProminent)

                    Button(
                        NSLocalizedString(
                            "Settings.about.quit",
                            value: "Quit",
                            comment: "Quit action."
                        ),
                        action: store.quit
                    )
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

extension Zenith {
    var localizedName: String {
        switch self {
        case .official:
            return LocalizedString.SunsetSunrise.official
        case .civil:
            return LocalizedString.SunsetSunrise.civil
        case .nautical:
            return LocalizedString.SunsetSunrise.nautical
        case .astronomical:
            return LocalizedString.SunsetSunrise.astronomical
        case .custom:
            return LocalizedString.SunsetSunrise.customRange
        case .system:
            return LocalizedString.SunsetSunrise.system
        }
    }
}
