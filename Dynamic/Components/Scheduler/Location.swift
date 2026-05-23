//
//  Location.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 11/17/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import CoreLocation
import Schedule

public enum Location {
    case current(CLLocation)
    case cached(CLLocation)
    case failed(Error)
}

final class LocationManager: NSObject, CLLocationManagerDelegate {
    public static let serial = LocationManager()

    private var retryCount = 5
    private let timeout = 10.seconds
    typealias Callback = (process: Handler<Location>, onTimeout: Task)

    private let lock = NSLock()
    private var callbacks: [Callback] = []
    private func callback(_ location: Location) {
        lock.lock()
        let pendingCallbacks = callbacks
        callbacks = []
        retryCount = 5
        lock.unlock()

        guard !pendingCallbacks.isEmpty else { return }
        stopUpdatingLocationIfIdle()
        for callback in pendingCallbacks {
            callback.onTimeout.cancel()
            callback.process(location)
        }
    }

    public func fetch(then processor: @escaping Handler<Location>) {
        lock.lock()
        let task = Plan.after(timeout).do(action: onTimeout)
        callbacks.append((processor, task))
        lock.unlock()
        startUpdatingLocation()
    }

    private func onTimeout(_ task: Task) {
        lock.lock()
        guard let idx = callbacks.firstIndex(where: { $0.onTimeout == task }) else {
            lock.unlock()
            return
        }
        let callback = callbacks.remove(at: idx)
        callback.onTimeout.cancel()
        lock.unlock()

        stopUpdatingLocationIfIdle()
        onError(AnError(errorDescription:
            LocalizedString.Location.timeout
        ), run: callback.process)
    }

    public weak var delegate: CLLocationManagerDelegate?
    private lazy var manager: CLLocationManager = {
        var manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationDidChange(manager)
    }

    private func authorizationDidChange(_ manager: CLLocationManager) {
        delegate?.locationManagerDidChangeAuthorization?(manager)
        guard !Location.deniedAccess else {
            onError(CLError.denied)
            return
        }
        startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        preferences.location = location
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            if let name = placemarks?.first?.name {
                preferences.placemark = name
            }
        }
        callback(.current(location))
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        retryCount -= 1
        guard retryCount <= 0 else { return }
        onError(error)
    }

    private func startUpdatingLocation() {
        if Location.deniedAccess {
            onError(CLError.denied)
        } else {
            manager.startUpdatingLocation()
        }
    }

    private func stopUpdatingLocationIfIdle() {
        lock.lock()
        let shouldStopUpdating = callbacks.isEmpty
        lock.unlock()
        if shouldStopUpdating { manager.stopUpdatingLocation() }
    }

    private func onError(_ error: Error, run callback: Handler<Location>! = nil) {
        let callback = callback ?? self.callback
        if let location = preferences.location {
            callback(.cached(location))
        } else {
            callback(.failed(error))
        }
    }
}

extension Location {
    static func alertNotAvailable(dueTo error: Error? = nil) {
        showAlert(withConfiguration: { alert in
            alert.alertStyle = .warning
            alert.messageText = error == CLError.denied
                ? LocalizedString.Location.notAuthorized
                : LocalizedString.Location.notAvailable
            guard let error = error else { return }
            alert.informativeText = error.localizedDescription
        })
    }
}

// MARK: - Core Location

extension Location {
    static var deniedAccess: Bool {
        let status = CLLocationManager().authorizationStatus
        switch status {
        case .authorizedAlways, .notDetermined:
            return false
        case .denied, .restricted:
            return true
        @unknown default:
            remindReportingBug(status.debugDescription)
            return false
        }
    }

    static var allowsAccess: Bool {
        let status = CLLocationManager().authorizationStatus
        switch status {
        case .authorizedAlways:
            return true
        case .denied, .notDetermined, .restricted:
            return false
        @unknown default:
            remindReportingBug(status.debugDescription)
            return false
        }
    }
}

extension CLError {
    static let nsDenied = NSError(
        domain: CLError.errorDomain,
        code: CLError.Code.denied.rawValue,
        userInfo: nil
    )
    static let denied = CLError(_nsError: nsDenied)
}

func == (lhs: Error?, rhs: CLError) -> Bool {
    return CLError.nsDenied.isEqual(to: lhs)
}

private extension CLAuthorizationStatus {
    var debugDescription: String {
        switch self {
        case .notDetermined:
            return "CLAuthorizationStatus.notDetermined"
        case .restricted:
            return "CLAuthorizationStatus.restricted"
        case .denied:
            return "CLAuthorizationStatus.denied"
        case .authorizedAlways:
            return "CLAuthorizationStatus.authorizedAlways"
        @unknown default:
            return "CLAuthorizationStatus.\(self.rawValue)"
        }
    }
}
