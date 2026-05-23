//
//  Scheduler.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 6/13/18.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import CoreLocation
import UserNotifications
import Schedule

public final class Scheduler: NSObject {
    public static let shared = Scheduler()

    private var task: Task?

    public func cancel() {
        task = nil
    }

    @objc public func schedule() {
        if preferences.AppleInterfaceStyleSwitchesAutomatically { return }
        func processLocation(_ result: Location) {
            switch result {
            case .current(let location):
                scheduleAtLocation(location)
            case .cached(let location):
                scheduleAtCachedLocation(location)
            case .failed(let error):
                Location.alertNotAvailable(dueTo: error)
            }
        }
        LocationManager.serial.fetch(then: processLocation)
    }

    private func scheduleAtLocation(_ location: CLLocation?) {
        UserNotification.removeAll()
        let decision = mode(atLocation: location?.coordinate)
        decision.style.enable()
        guard let date = decision.date else { return }
        task = Plan.at(date).do { [weak self] in self?.schedule() }
    }

    @discardableResult
    private func scheduleAtCachedLocation(_ location: CLLocation) -> Bool {
        guard preferences.scheduleZenithType.hasSunriseSunsetTime else {
            scheduleAtLocation(nil)
            return false
        }
        UserNotification.removeAll()
        UserNotification.send(.useCache,
                              title: LocalizedString.Location.useCache,
                              subtitle: preferences.placemark ??
                                String(format:"<%.2f,%.2f>",
                                       location.coordinate.latitude,
                                       location.coordinate.longitude))
        scheduleAtLocation(location)
        return true
    }

    // Mark: - Mode

    public func updateSchedule(then process: @escaping Handler<Result<Void, Error>>) {
        if preferences.AppleInterfaceStyleSwitchesAutomatically {
            return process(.failure(AnError(errorDescription: "AppleInterfaceStyleSwitchesAutomatically")))
        }
        getCurrentMode { process($0.map { _ in }) }
    }

    private func getCurrentMode(then process: @escaping Handler<Result<Mode, Error>>) {
        LocationManager.serial.fetch { [unowned self] in
            switch $0 {
            case .current(let location), .cached(let location):
                process(.success(self.mode(atLocation: location.coordinate)))
            case .failed(let error):
                process(.failure(error))
            }
        }
    }

    public typealias Mode = (style: AppleInterfaceStyle, date: Date?)

    public func mode(atLocation coordinate: CLLocationCoordinate2D?, now: Date? = nil) -> Mode {
        let now = now ?? Date()
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) else {
            return (.systemCurrent, nil)
        }
        if let coordinate = coordinate
            , CLLocationCoordinate2DIsValid(coordinate)
            , preferences.scheduleZenithType.hasSunriseSunsetTime {
            return dynamicCurrentMode(fromToday: now, andTomorrow: tomorrow, at: coordinate)
        } else {
            return staticCurrentMode(fromToday: now, andTomorrow: tomorrow)
        }
    }

    private func dynamicCurrentMode(fromToday now: Date, andTomorrow tomorrow: Date,
                                    at coordinate: CLLocationCoordinate2D) -> Mode {
        let scheduledDate: Date
        guard
            let solar = Solar(for: now, coordinate: coordinate),
            let dates = solar.sunriseSunsetTime
        else {
            return staticCurrentMode(fromToday: now, andTomorrow: tomorrow)
        }
        if now < dates.sunrise {
            scheduledDate = dates.sunrise
            guard
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now),
                let pastSolar = Solar(for: yesterday, coordinate: coordinate),
                let pastDates = pastSolar.sunriseSunsetTime
            else {
                return staticCurrentMode(fromToday: now, andTomorrow: tomorrow)
            }
            preferences.scheduleStart = pastDates.sunset
            preferences.scheduleEnd = scheduledDate
            return (.darkAqua, scheduledDate)
        } else {
            guard
                let futureSolar = Solar(for: tomorrow, coordinate: coordinate),
                let futureDates = futureSolar.sunriseSunsetTime
            else {
                return staticCurrentMode(fromToday: now, andTomorrow: tomorrow)
            }
            if now < dates.sunset {
                scheduledDate = dates.sunset
                preferences.scheduleStart = scheduledDate
                preferences.scheduleEnd = futureDates.sunrise
                return (.aqua, scheduledDate)
            } else { // after sunset
                preferences.scheduleStart = dates.sunset
                scheduledDate = futureDates.sunrise
                preferences.scheduleEnd = scheduledDate
                return (.darkAqua, scheduledDate)
            }
        }
    }

    private func staticCurrentMode(fromToday now: Date, andTomorrow tomorrow: Date) -> Mode {
        if preferences.scheduleZenithType.hasSunriseSunsetTime {
            preferences.scheduleZenithType = .custom
        }
        let current = Calendar.current.dateComponents([.hour, .minute], from: now)
        let start = Calendar.current.dateComponents(
            [.hour, .minute], from: preferences.scheduleStart
        )
        let end = Calendar.current.dateComponents(
            [.hour, .minute], from: preferences.scheduleEnd
        )
        if start == end { return (.systemCurrent, nil) }
        guard
            let currentHour = current.hour,
            let currentMinute = current.minute,
            let startHour = start.hour,
            let startMinute = start.minute,
            let endHour = end.hour,
            let endMinute = end.minute
        else {
            return (.systemCurrent, nil)
        }
        let currentTime = ScheduleTime(hour: currentHour, minute: currentMinute)
        let startTime = ScheduleTime(hour: startHour, minute: startMinute)
        let endTime = ScheduleTime(hour: endHour, minute: endMinute)
        if currentTime < endTime {
            return (.darkAqua, Calendar.current.date(
                bySettingHour: endHour, minute: endMinute, second: 0, of: now
            ))
        } else if currentTime < startTime {
            return (.aqua, Calendar.current.date(
                bySettingHour: startHour, minute: startMinute, second: 0, of: now
            ))
        } else if startTime > endTime {
            return (.darkAqua, Calendar.current.date(
                bySettingHour: endHour, minute: endMinute, second: 0, of: tomorrow
            ))
        } else {
            return (.aqua, Calendar.current.date(
                bySettingHour: startHour, minute: startMinute, second: 0, of: tomorrow
            ))
        }
    }

    // MARK: - Missed Schedule

    private override init() {
        super.init()
        let notifications = [
            NSWorkspace.didWakeNotification,
            NSWorkspace.screensDidWakeNotification,
            NSWorkspace.sessionDidBecomeActiveNotification
        ]
        for name in notifications {
            NSWorkspace.shared.notificationCenter.addObserver(
                self, selector: #selector(workspaceDidWake),
                name: name, object: nil
            )
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(systemClockDidChange),
            name: Notification.Name.NSSystemClockDidChange,
            object: nil
        )
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    private var fakeClockChange: Task?

    /// Usually it takes 5~15 seconds to happen, so 30 seconds
    /// is a relatively safe but reasonable long waiting time.
    private let waitForfakeClockChange = 30.seconds

    /// 2 cases here:
    /// either a real clock change happened
    /// or Mac just wake up from a long sleep
    @objc private func systemClockDidChange() {
        guard fakeClockChange == nil else { return }
        schedule()
    }

    @objc private func workspaceDidWake() {
        fakeClockChange = Plan.after(waitForfakeClockChange).do { [weak self] in
            self?.fakeClockChange = nil
        }
        if let task = task {
            guard let expected = task.estimatedNextExecutionDate else {
                defer { schedule() }
                return remindReportingBug("nil: estimatedNextExecution", issueID: 59)
            }
            if expected < Date() && task.executionCount < 1 {
                task.executeNow()
            }
        } else if preferences.scheduled {
            schedule() // not sure why would I expect this?
        }
    }
}

private struct ScheduleTime: Comparable {
    let hour: Int
    let minute: Int

    static func < (lhs: ScheduleTime, rhs: ScheduleTime) -> Bool {
        lhs.hour < rhs.hour
            || lhs.hour == rhs.hour && lhs.minute < rhs.minute
    }
}
