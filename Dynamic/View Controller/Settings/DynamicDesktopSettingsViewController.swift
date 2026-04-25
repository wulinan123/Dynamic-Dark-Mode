//
//  DynamicDesktopSettingsViewController.swift
//  Dynamic Dark Mode
//

import Foundation

enum DesktopWallpaperKind {
    case light
    case dark
}

struct DesktopWallpaperSelection: Equatable {
    private(set) var lightURL: URL?
    private(set) var darkURL: URL?
    
    init(lightURL: URL? = nil, darkURL: URL? = nil) {
        self.lightURL = Self.sanitize(lightURL)
        self.darkURL = Self.sanitize(darkURL)
    }
    
    var hasAnySelection: Bool {
        lightURL != nil || darkURL != nil
    }
    
    mutating func set(_ url: URL?, for kind: DesktopWallpaperKind) {
        switch kind {
        case .light:
            lightURL = Self.sanitize(url)
        case .dark:
            darkURL = Self.sanitize(url)
        }
    }
    
    mutating func clear() {
        lightURL = nil
        darkURL = nil
    }
    
    static func sanitize(_ url: URL?) -> URL? {
        guard let url, url.isFileURL else { return nil }
        return url.standardizedFileURL
    }
}

#if canImport(AppKit) && !SWIFT_PACKAGE
import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class DynamicDesktopSettingsViewController: NSViewController {
    @IBOutlet weak var lightDesktopButton: NSButton?
    @IBOutlet weak var darkDesktopButton: NSButton?
    @IBOutlet weak var clearButton: NSButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        syncLegacyButtons()
    }
    
    @IBAction func clearDesktop(_ sender: Any?) {
        preferences.lightDesktopURL = nil
        preferences.darkDesktopURL = nil
        AppleInterfaceStyle.updateWallpaper()
        syncLegacyButtons()
    }
    
    static func selectImage(then completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.resolvesAliases = true
        panel.allowedContentTypes = [.image]
        panel.canDownloadUbiquitousContents = true
        panel.canResolveUbiquitousConflicts = true
        panel.begin { response in
            guard response == .OK else { return completion(nil) }
            completion(DesktopWallpaperSelection.sanitize(panel.url))
        }
    }
    
    private func syncLegacyButtons() {
        lightDesktopButton?.title = title(for: preferences.lightDesktopURL, kind: .light)
        darkDesktopButton?.title = title(for: preferences.darkDesktopURL, kind: .dark)
        clearButton?.isEnabled = preferences.lightDesktopURL != nil || preferences.darkDesktopURL != nil
    }
    
    private func title(for url: URL?, kind: DesktopWallpaperKind) -> String {
        if let fileName = url?.lastPathComponent, !fileName.isEmpty {
            return fileName
        }
        switch kind {
        case .light:
            return NSLocalizedString(
                "Settings.desktop.preview.light",
                value: "Light appearance",
                comment: "Light wallpaper preview title."
            )
        case .dark:
            return NSLocalizedString(
                "Settings.desktop.preview.dark",
                value: "Dark appearance",
                comment: "Dark wallpaper preview title."
            )
        }
    }
}

struct DesktopPreviewRow: View {
    let title: String
    let url: URL?
    let symbolName: String
    
    private var fallbackName: String {
        NSLocalizedString(
            "Settings.desktop.preview.empty",
            value: "Not configured",
            comment: "Desktop preview empty label."
        )
    }
    
    var body: some View {
        HStack(spacing: 14) {
            preview
                .frame(width: 88, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(url?.lastPathComponent ?? fallbackName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private var preview: some View {
        if
            let url,
            let image = NSImage(contentsOf: url)
        {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
                Image(systemName: symbolName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DynamicDesktopPanelView: View {
    @ObservedObject var store: SettingsStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        SettingsPaneScroll(
            title: NSLocalizedString(
                "Settings.desktop.panel.title",
                value: "Manage Wallpaper Mapping",
                comment: "Desktop panel title."
            ),
            subtitle: NSLocalizedString(
                "Settings.desktop.panel.subtitle",
                value: "Pick optional images for light and dark appearance.",
                comment: "Desktop panel subtitle."
            )
        ) {
            SettingsCard(
                title: NSLocalizedString(
                    "Settings.desktop.panel.mapping.title",
                    value: "Appearance Mapping",
                    comment: "Desktop panel mapping title."
                ),
                subtitle: NSLocalizedString(
                    "Settings.desktop.panel.mapping.subtitle",
                    value: "When present, wallpapers are applied every time appearance changes.",
                    comment: "Desktop panel mapping subtitle."
                )
            ) {
                DesktopPreviewRow(
                    title: NSLocalizedString(
                        "Settings.desktop.preview.light",
                        value: "Light appearance",
                        comment: "Light wallpaper preview title."
                    ),
                    url: store.lightDesktopURL,
                    symbolName: "sun.max.fill"
                )
                DesktopPreviewRow(
                    title: NSLocalizedString(
                        "Settings.desktop.preview.dark",
                        value: "Dark appearance",
                        comment: "Dark wallpaper preview title."
                    ),
                    url: store.darkDesktopURL,
                    symbolName: "moon.fill"
                )
                
                HStack(spacing: 12) {
                    Button(
                        NSLocalizedString(
                            "Settings.desktop.panel.selectLight",
                            value: "Choose Light Wallpaper…",
                            comment: "Select light wallpaper action."
                        ),
                        action: store.selectLightWallpaper
                    )
                    .buttonStyle(.bordered)
                    
                    Button(
                        NSLocalizedString(
                            "Settings.desktop.panel.selectDark",
                            value: "Choose Dark Wallpaper…",
                            comment: "Select dark wallpaper action."
                        ),
                        action: store.selectDarkWallpaper
                    )
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    if store.lightDesktopURL != nil || store.darkDesktopURL != nil {
                        Button(
                            NSLocalizedString(
                                "Settings.desktop.clear",
                                value: "Clear",
                                comment: "Clear wallpaper mappings action."
                            ),
                            action: store.clearWallpapers
                        )
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            HStack {
                Spacer()
                Button(
                    NSLocalizedString(
                        "Settings.desktop.panel.done",
                        value: "Done",
                        comment: "Dismiss desktop panel action."
                    )
                ) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}
#endif
