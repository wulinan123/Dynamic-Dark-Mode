//
//  AllowLocationViewController.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 9/28/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import CoreLocation
import SwiftUI

class AllowLocationViewController: NSViewController, LastSetupStep { }

struct LocationPermissionStepView: View {
    let state: OnboardingPermissionState
    let openPreferences: () -> Void
    let continueAction: () -> Void
    
    var body: some View {
        OnboardingStepCard(
            eyebrow: NSLocalizedString(
                "Onboarding.location.eyebrow",
                value: "Location Permission",
                comment: "Location step eyebrow."
            ),
            title: NSLocalizedString(
                "Onboarding.location.title",
                value: "Use your location for sunset and sunrise schedules.",
                comment: "Location step title."
            ),
            message: NSLocalizedString(
                "Onboarding.location.message",
                value: "Location is only used to calculate daylight-based switching windows. If you skip this, you can still use custom schedules.",
                comment: "Location step message."
            ),
            symbolName: "location.north.circle"
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
                        value: "Finish Without It",
                        comment: "Finish onboarding without permission."
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
            Label(message, systemImage: "mappin.slash.circle.fill")
                .foregroundStyle(.orange)
        }
    }
}
