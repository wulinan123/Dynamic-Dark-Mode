//
//  SettingsViewController + TouchBar.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 6/9/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import AppKit
import MASShortcut
import SwiftUI

struct SettingsPaneScroll<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.98, blue: 1.0),
                    Color(red: 0.95, green: 0.97, blue: 0.95),
                    Color(red: 0.99, green: 0.96, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                        Text(subtitle)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    
                    content
                }
                .padding(28)
            }
        }
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
            content
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.2))
        )
    }
}

struct WindowAccessor: NSViewRepresentable {
    let identifier: NSUserInterfaceItemIdentifier
    let configure: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            if let window = view.window {
                applyConfiguration(to: window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                applyConfiguration(to: window)
            }
        }
    }
    
    private func applyConfiguration(to window: NSWindow) {
        window.identifier = identifier
        configure(window)
    }
}

struct ShortcutRecorderView: NSViewRepresentable {
    func makeNSView(context: Context) -> MASShortcutView {
        let view = MASShortcutView(frame: .zero)
        view.associatedUserDefaultsKey = Preferences.toggleShortcutKey
        return view
    }
    
    func updateNSView(_ nsView: MASShortcutView, context: Context) { }
}
