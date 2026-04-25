//
//  AppleInterfaceStyle.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 5/3/19.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import Foundation

public enum AppleInterfaceStyle: String {
    case aqua
    case darkAqua
}

// MARK: - Toggle Dark Mode

extension AppleInterfaceStyle {
    static func toggle(then completion: CompletionHandler? = nil) {
        AppleScript.toggleDarkMode.execute(then: completion)
    }
    
    func enable(then completion: CompletionHandler? = nil) {
        guard AppleInterfaceStyle.systemCurrent != self else { return }
        switch self {
        case .aqua:
            AppleScript.disableDarkMode.execute(then: completion)
        case .darkAqua:
            AppleScript.enableDarkMode.execute(then: completion)
        }
    }
    
    static func updateWallpaper() {
        guard let url = systemCurrent == .darkAqua
            ? preferences.darkDesktopURL
            : preferences.lightDesktopURL
            else { return }
        let workspace = NSWorkspace.shared
        for screen in NSScreen.screens {
            try? workspace.setDesktopImageURL(url, for: screen)
        }
    }
}

extension AppleInterfaceStyle {
    var toggled: AppleInterfaceStyle {
        switch self {
        case .aqua:
            return .darkAqua
        case .darkAqua:
            return .aqua
        }
    }
}
