//
//  SetupStep.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 12/11/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import CoreLocation
import SwiftUI

protocol SetupStep: AnyObject { }
protocol LastSetupStep: SetupStep { }

var setupSteps = [NSViewController]()

func rewindSetupSteps() {
    setupSteps.removeAll()
}

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case automation
    case location
    
    var index: Int { rawValue + 1 }
    
    var title: String {
        switch self {
        case .welcome:
            return NSLocalizedString(
                "Onboarding.step.welcome",
                value: "Welcome",
                comment: "Onboarding step title."
            )
        case .automation:
            return NSLocalizedString(
                "Onboarding.step.automation",
                value: "Automation",
                comment: "Onboarding step title."
            )
        case .location:
            return NSLocalizedString(
                "Onboarding.step.location",
                value: "Location",
                comment: "Onboarding step title."
            )
        }
    }
}

enum OnboardingPermissionState {
    case idle
    case checking
    case denied(String)
}

@MainActor
final class OnboardingFlowModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var step: OnboardingStep = .welcome
    @Published var automationState: OnboardingPermissionState = .idle
    @Published var locationState: OnboardingPermissionState = .idle
    
    override init() {
        super.init()
        LocationManager.serial.delegate = self
    }
    
    func continueFromWelcome() {
        step = .automation
    }
    
    func checkAutomationPermission() {
        guard step == .automation, case .idle = automationState else { return }
        automationState = .checking
        AppleScript.requestPermission { [weak self] authorized in
            DispatchQueue.main.async {
                guard let self else { return }
                if authorized {
                    self.step = .location
                    self.automationState = .idle
                    self.checkLocationPermissionIfNeeded()
                } else {
                    self.automationState = .denied(AppleScript.notAuthorized)
                }
            }
        }
    }
    
    func openAutomationPreferences() {
        AppleScript.redirectToSystemPreferences()
    }
    
    func continueWithoutAutomation() {
        step = .location
        checkLocationPermissionIfNeeded()
    }
    
    func checkLocationPermissionIfNeeded() {
        guard step == .location else { return }
        if Location.allowsAccess {
            WindowRouter.shared.finishOnboarding()
            return
        }
        guard case .idle = locationState else { return }
        locationState = .checking
        LocationManager.serial.fetch { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .current:
                    WindowRouter.shared.finishOnboarding()
                case .cached:
                    self.locationState = .denied(LocalizedString.Location.useCache)
                case .failed(let error):
                    self.locationState = .denied(
                        error == CLError.denied
                        ? LocalizedString.Location.notAuthorized
                        : LocalizedString.Location.notAvailable
                    )
                }
            }
        }
    }
    
    func openLocationPreferences() {
        openURL("x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")
    }
    
    func continueWithoutLocation() {
        WindowRouter.shared.finishOnboarding()
    }
    
    func finishOnboarding() {
        WindowRouter.shared.finishOnboarding()
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard Location.allowsAccess else { return }
        Task { @MainActor in
            WindowRouter.shared.finishOnboarding()
        }
    }
}
