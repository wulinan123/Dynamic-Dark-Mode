//
//  InitialSetupViewController.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 9/16/19.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import SwiftUI

class InitialSetupViewController: NSViewController { }

struct WelcomeStepView: View {
    let continueAction: () -> Void
    let skipAction: () -> Void
    
    var body: some View {
        OnboardingStepCard(
            eyebrow: NSLocalizedString(
                "Onboarding.eyebrow",
                value: "Dynamic Dark Mode",
                comment: "Wizard eyebrow."
            ),
            title: NSLocalizedString(
                "Onboarding.welcome.title",
                value: "A lighter setup for a darker Mac.",
                comment: "Welcome step title."
            ),
            message: NSLocalizedString(
                "Onboarding.welcome.message",
                value: "Modernized controls, faster appearance syncing, and a cleaner settings experience are ready. We only need two permissions to finish setup.",
                comment: "Welcome step message."
            ),
            symbolName: "sparkles"
        ) {
            Button(
                NSLocalizedString(
                    "Onboarding.action.skip",
                    value: "Skip for Now",
                    comment: "Skip onboarding action."
                ),
                action: skipAction
            )
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            
            Spacer()
            
            Button(
                NSLocalizedString(
                    "Onboarding.action.continue",
                    value: "Continue",
                    comment: "Continue onboarding action."
                ),
                action: continueAction
            )
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
