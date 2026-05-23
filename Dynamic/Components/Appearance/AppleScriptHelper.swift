//
//  AppleScriptHelper.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 6/7/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import Cocoa

// MARK: - All Apple Scripts

public enum AppleScript: String, CaseIterable {
    case toggleDarkMode = "not dark mode"
    case enableDarkMode = "true"
    case disableDarkMode = "false"
}

// MARK: - Execution

extension AppleScript {
    public func execute(then completion: CompletionHandler? = nil) {
        let frontmostApplication = NSWorkspace.shared.frontmostApplication
        AppleScript.requestPermission { authorized in
            let mutate = {
                if authorized {
                    self.useAppleScriptImplementation()
                } else {
                    self.useNonAppStoreCompliantImplementation()
                }
                self.finishMutation(
                    restoring: frontmostApplication,
                    then: completion
                )
            }
            DispatchQueue.main.async(execute: mutate)
        }
    }

    // MARK: Deprecated API

    /// Turns dark mode on/off/to the opposite.
    private var source: String {
        return """
        tell application "System Events"
            tell appearance preferences to set dark mode to \(rawValue)
        end tell
        """
    }

    private func useAppleScriptImplementation() {
        guard let script = NSAppleScript(source: self.source) else {
            useNonAppStoreCompliantImplementation()
            return
        }
        var errorInfo: NSDictionary? = nil
        script.executeAndReturnError(&errorInfo)
        // Handle errors
        if errorInfo != nil {
            useNonAppStoreCompliantImplementation()
        }
    }

    // MARK: Private API

    private func useNonAppStoreCompliantImplementation() {
        switch self {
        case .toggleDarkMode:
            SLSSetAppearanceThemeLegacy(!SLSGetAppearanceThemeLegacy())
        case .enableDarkMode:
            SLSSetAppearanceThemeLegacy(true)
        case .disableDarkMode:
            SLSSetAppearanceThemeLegacy(false)
        }
    }

    private func finishMutation(
        restoring application: NSRunningApplication?,
        then completion: CompletionHandler?
    ) {
        let refresh = {
            MainActor.assumeIsolated {
                AppearanceMonitor.shared.refresh()
                completion?()
                application?.activate()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: refresh)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            MainActor.assumeIsolated {
                AppearanceMonitor.shared.refresh()
            }
        }
    }
}

// MARK: - Permission

extension AppleScript {
    public static let notAuthorized = NSLocalizedString(
        "AppleScript.authorization.error",
        value: "You didn't allow Dynamic Dark Mode to manage dark mode",
        comment: ""
    )

    public static func redirectToSystemPreferences() {
        openURL("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
    }

    public static func requestPermission(
        retryOnInternalError: Bool = true,
        then process: @escaping Handler<Bool>
    ) {
        DispatchQueue.global().async {
            let systemEvents = "com.apple.systemevents"
            launchSystemEventsIfNeeded()
            let target = NSAppleEventDescriptor(bundleIdentifier: systemEvents)
            let status = AEDeterminePermissionToAutomateTarget(
                target.aeDesc, typeWildCard, typeWildCard, true
            )
            switch Int(status) {
            case Int(noErr):
                return process(true)
            case errAEEventNotPermitted:
                break
            case errOSAInvalidID, -1751,
                 errAEEventWouldRequireUserConsent,
                 procNotFound:
                if retryOnInternalError {
                    return requestPermission(retryOnInternalError: false, then: process)
                }
            default:
                remindReportingBug("OSStatus \(status)")
            }
            process(false)
        }
    }

    private static func launchSystemEventsIfNeeded() {
        let workspace = NSWorkspace.shared
        let systemEvents = "com.apple.systemevents"
        guard
            let url = workspace.urlForApplication(withBundleIdentifier: systemEvents),
            workspace.open(url)
        else {
            remindReportingBug("Could not find System Events")
            return
        }
    }
}
