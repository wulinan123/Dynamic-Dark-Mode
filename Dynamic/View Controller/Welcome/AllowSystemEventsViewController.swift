//
//  AllowSystemEventsViewController.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 9/25/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import SwiftUI

class AllowSystemEventsViewController: NSViewController, SetupStep { }

struct AutomationPermissionStepView: View {
    let state: OnboardingPermissionState
    let openPreferences: () -> Void
    let continueAction: () -> Void
    
    var body: some View {
        OnboardingStepCard(
            eyebrow: NSLocalizedString(
                "Onboarding.automation.eyebrow",
                value: "Automation Permission",
                comment: "Automation step eyebrow."
            ),
            title: NSLocalizedString(
                "Onboarding.automation.title",
                value: "Allow Dynamic Dark Mode to switch appearance.",
                comment: "Automation step title."
            ),
            message: NSLocalizedString(
                "Onboarding.automation.message",
                value: "This grants access to System Events so the app can flip between light and dark appearance from the menu bar, shortcuts, Touch Bar, and automation rules.",
                comment: "Automation step message."
            ),
            symbolName: "switch.2"
        ) {
            statusView
            
            HStack(spacing: 12) {
                Button(
                    NSLocalizedString(
                        "SystemPreferences.open",
                        value: "Open System Settings",
                        comment: "Open system settings action."
                    ),
                    action: openPreferences
                )
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Spacer()
                
                Button(
                    NSLocalizedString(
                        "SystemPreferences.skip",
                        value: "Continue Without It",
                        comment: "Skip permission step."
                    ),
                    action: continueAction
                )
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
    
    @ViewBuilder
    private var statusView: some View {
        switch state {
        case .idle:
            EmptyView()
        case .checking:
            Label(
                NSLocalizedString(
                    "Onboarding.permission.checking",
                    value: "Checking permission…",
                    comment: "Permission check in progress."
                ),
                systemImage: "hourglass"
            )
            .foregroundStyle(.secondary)
        case .denied(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
    }
}
