//
//  ScreenBrightnessObserver.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 6/8/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import Cocoa
import Schedule

final class ScreenBrightnessObserver: NSObject {

    private var notificationPort: IONotificationPortRef?
    private var notificationObject: io_object_t = IO_OBJECT_NULL
    private let queue = DispatchQueue(label: "ddm.queue.brightness")
    private lazy var lastBrightness = NSScreen.brightness
    private var callback: IOServiceInterestCallback = { (ctx, service, messageType, messageArgument) in
        guard let ctx = ctx else { return }
        let observer = Unmanaged<ScreenBrightnessObserver>.fromOpaque(ctx).takeUnretainedValue()
        let newBrightness = NSScreen.brightness
        guard observer.lastBrightness != newBrightness else { return }
        observer.lastBrightness = newBrightness
        observer.setNeedsUpdate()
    }

    static let shared = ScreenBrightnessObserver()
    private override init() { super.init() }
    deinit { stopObserving() }

    public func startObserving(withInitialUpdate: Bool = true) {
        stopObserving()
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleBacklightDisplay"))
        guard service != IO_OBJECT_NULL else {
            return reportObservationUnavailable()
        }
        defer { IOObjectRelease(service) }
        guard let port = IONotificationPortCreate(kIOMainPortDefault) else {
            return reportObservationUnavailable()
        }
        IONotificationPortSetDispatchQueue(port, queue)
        let ctx = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let result = IOServiceAddInterestNotification(
            port,
            service,
            kIOGeneralInterest,
            callback,
            ctx,
            &notificationObject
        )
        guard result == kIOReturnSuccess else {
            notificationObject = IO_OBJECT_NULL
            IONotificationPortDestroy(port)
            return reportObservationUnavailable()
        }
        notificationPort = port
        lastBrightness = NSScreen.brightness
        if withInitialUpdate {
            setNeedsUpdate()
        }
    }

    public var suggestedMode: AppleInterfaceStyle {
        let brightness = NSScreen.brightness
        let threshold = preferences.brightnessThreshold
        return brightness < threshold ? .darkAqua : .aqua
    }

    private var task: Task?
    private func setNeedsUpdate() {
        task = Plan.after(0.5.seconds).do(queue: .main, action: _updateForBrightnessChange)
    }

    private func _updateForBrightnessChange() {
        guard NSScreen.brightness >= 0 else { return }
        let newValue = suggestedMode
        guard AppleInterfaceStyle.systemCurrent != newValue else { return }
        newValue.enable()
    }

    public func stopObserving() {
        if notificationObject != IO_OBJECT_NULL {
            IOObjectRelease(notificationObject)
            notificationObject = IO_OBJECT_NULL
        }
        guard let port = notificationPort else { return }
        IONotificationPortDestroy(port)
        notificationPort = nil
    }

    private func reportObservationUnavailable() {
        debugPrint("Dynamic Dark Mode - Cannot observe screen brightness change.")
    }
}
