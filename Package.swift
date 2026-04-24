// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DynamicDarkModeSupportTests",
    products: [
        .library(name: "DesktopWallpaperSelection", targets: ["DesktopWallpaperSelection"])
    ],
    targets: [
        .target(
            name: "DesktopWallpaperSelection",
            path: "Dynamic/View Controller/Settings",
            sources: ["DynamicDesktopSettingsViewController.swift"]
        ),
        .testTarget(
            name: "DesktopWallpaperSelectionTests",
            dependencies: ["DesktopWallpaperSelection"],
            path: "Tests/DesktopWallpaperSelectionTests"
        )
    ]
)
