import Foundation
import os

nonisolated enum AppLog {
    static let subsystem = "app.mousemover.MouseMover"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let engine = Logger(subsystem: subsystem, category: "engine")
    static let schedule = Logger(subsystem: subsystem, category: "schedule")
    static let movement = Logger(subsystem: subsystem, category: "movement")
    static let settings = Logger(subsystem: subsystem, category: "settings")
    static let permission = Logger(subsystem: subsystem, category: "permission")
    static let loginItem = Logger(subsystem: subsystem, category: "login-item")
}

extension EnginePhase {
    var logDescription: String {
        switch self {
        case .off: "off"
        case .needsPermission: "needsPermission"
        case .inactiveDay: "inactiveDay"
        case .waiting(let until):
            "waiting until \(until.formatted(date: .omitted, time: .standard))"
        case .waitingForIdle(let until):
            "waitingForIdle until \(until.formatted(date: .omitted, time: .standard))"
        case .pausedForUser: "pausedForUser"
        case .jiggling: "jiggling"
        case .finishedForToday: "finishedForToday"
        }
    }
}

extension DailyWindow {
    var logDescription: String {
        let startText = start.formatted(date: .omitted, time: .shortened)
        let endText = end.formatted(date: .omitted, time: .shortened)
        let overnight = isOvernight ? " overnight" : ""
        return "\(dayStamp) \(startText)–\(endText)\(overnight) offsets start=\(signed(startOffsetMinutes)) stop=\(signed(stopOffsetMinutes))"
    }
}

extension ScheduleEvaluation {
    var logDescription: String {
        switch self {
        case .alwaysOn: "alwaysOn"
        case .inactiveDay: "inactiveDay"
        case .waiting(let until, _):
            "waiting until \(until.formatted(date: .omitted, time: .standard))"
        case .active: "active"
        case .finished: "finished"
        }
    }
}

extension TimeOfDay {
    var logDescription: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

extension ScheduleSettings {
    var logDescription: String {
        let days = activeWeekdays.rawValues.sorted().map(String.init).joined(separator: ",")
        return "enabled=\(isEnabled) \(start.logDescription)–\(stop.logDescription) threshold=±\(thresholdMinutes)m weekdays=[\(days)]"
    }
}

extension MovementSettings {
    var logDescription: String {
        "pattern=\(pattern.rawValue) interval=\(intervalSeconds)s jitter=\(intervalJitterPercent)% distance=\(distancePixels)px jitter=\(distanceJitterPercent)% duration=\(durationMilliseconds)ms smoothness=\(Int((smoothness * 100).rounded()))% restore=\(restorePosition) pause=\(pauseWhileUsingPointer) grace=\(idleGraceSeconds)s"
    }
}

extension AppSettings {
    var logDescription: String {
        "enabled=\(isEnabled) launchAtLogin=\(launchAtLogin) \(movement.pattern.rawValue) schedule=\(schedule.logDescription)"
    }
}

private func signed(_ value: Int) -> String {
    value >= 0 ? "+\(value)m" : "\(value)m"
}
