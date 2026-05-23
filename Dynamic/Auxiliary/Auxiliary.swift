//
//  Auxiliary.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 9/28/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import Cocoa

public typealias Handler<T> = (T) -> Void
public typealias CompletionHandler = () -> Void

func openURL(_ string: String) {
    guard let url = URL(string: string) else {
        remindReportingBug("Invalid URL: \(string)")
        return
    }
    if !NSWorkspace.shared.open(url) {
        remindReportingBug("Failed to open URL: \(string)")
    }
}
