//
//  AppDelegate.swift
//  DynamicLauncher
//
//  Created by Apollo Zhu on 6/9/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import Cocoa

let id = "io.github.wulinan123.Dynamic"

var noInstanceRunning: Bool {
    return NSRunningApplication
        .runningApplications(withBundleIdentifier: id)
        .filter { $0.isActive }
        .isEmpty
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        defer { NSApp.terminate(nil) }
        guard noInstanceRunning else { return }
        NSWorkspace.shared.launchApplication(
            withBundleIdentifier: id,
            options: .default,
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )
    }
}
