//
//  Welcome.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 9/26/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import SwiftUI

@MainActor
final class WindowRouter: NSObject, NSWindowDelegate {
    static let shared = WindowRouter()
    
    nonisolated static let onboardingWindowID = NSUserInterfaceItemIdentifier("io.github.apollozhu.dynamic.onboarding")
    nonisolated static let settingsWindowID = NSUserInterfaceItemIdentifier("io.github.apollozhu.dynamic.settings")
    
    private var onboardingWindowController: NSWindowController?
    
    private override init() {
        super.init()
    }
    
    @objc func showSettingsAction(_ sender: Any?) {
        showSettings()
    }
    
    func reopen() {
        if preferences.hasLaunchedBefore {
            showSettings()
        } else {
            showOnboarding()
        }
    }
    
    func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }
        let selectors = [
            NSSelectorFromString("showSettingsWindow:"),
            NSSelectorFromString("showPreferencesWindow:")
        ]
        for selector in selectors where NSApp.sendAction(selector, to: nil, from: nil) {
            return
        }
    }
    
    func closeSettingsWindow() {
        settingsWindow?.close()
    }
    
    func showOnboarding() {
        if let onboardingWindow = onboardingWindowController?.window {
            NSApp.activate(ignoringOtherApps: true)
            onboardingWindow.makeKeyAndOrderFront(nil)
            return
        }
        let hostingController = NSHostingController(rootView: OnboardingFlowView())
        let window = NSWindow(contentViewController: hostingController)
        window.identifier = Self.onboardingWindowID
        window.delegate = self
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.toolbarStyle = .unifiedCompact
        window.setContentSize(NSSize(width: 860, height: 580))
        window.center()
        let controller = NSWindowController(window: window)
        onboardingWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    func finishOnboarding() {
        closeOnboarding()
        preferences.hasLaunchedBefore = true
        Preferences.setupAsSuggested()
        AppBootstrapper.shared.startIfNeeded()
        showSettings()
    }
    
    func closeOnboarding() {
        onboardingWindowController?.close()
        onboardingWindowController = nil
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window.identifier == Self.onboardingWindowID {
            onboardingWindowController = nil
        }
    }
    
    private var settingsWindow: NSWindow? {
        NSApp.windows.first { $0.identifier == Self.settingsWindowID }
    }
}

@MainActor
final class Welcome: NSWindowController {
    static func show() {
        WindowRouter.shared.showOnboarding()
    }
    
    static func skip() {
        WindowRouter.shared.finishOnboarding()
    }
    
    static func close() {
        WindowRouter.shared.closeOnboarding()
    }
}

struct OnboardingFlowView: View {
    @StateObject private var model = OnboardingFlowModel()
    
    var body: some View {
        ZStack {
            OnboardingBackdrop()
            VStack(spacing: 28) {
                HStack(spacing: 12) {
                    ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                        stepPill(for: step)
                    }
                }
                .padding(.top, 12)
                
                currentStepView
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            .padding(32)
        }
        .frame(minWidth: 860, minHeight: 580)
        .onAppear {
            if model.step == .automation {
                model.checkAutomationPermission()
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.9), value: model.step)
        .background(
            WindowAccessor(identifier: WindowRouter.onboardingWindowID) { window in
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
            }
        )
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch model.step {
        case .welcome:
            WelcomeStepView(
                continueAction: model.continueFromWelcome,
                skipAction: model.finishOnboarding
            )
        case .automation:
            AutomationPermissionStepView(
                state: model.automationState,
                openPreferences: model.openAutomationPreferences,
                continueAction: model.continueWithoutAutomation
            )
            .onAppear {
                model.checkAutomationPermission()
            }
        case .location:
            LocationPermissionStepView(
                state: model.locationState,
                openPreferences: model.openLocationPreferences,
                continueAction: model.continueWithoutLocation
            )
            .onAppear {
                model.checkLocationPermissionIfNeeded()
            }
        }
    }
    
    private func stepPill(for step: OnboardingStep) -> some View {
        let isCurrent = step == model.step
        return HStack(spacing: 10) {
            Text("\(step.index)")
                .font(.headline.monospacedDigit())
            Text(step.title)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isCurrent ? .thickMaterial : .thinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(isCurrent ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.2))
        )
        .foregroundStyle(isCurrent ? .primary : .secondary)
    }
}
