import Foundation

struct WeekdaySet: Codable, Equatable, Sendable {
    /// `Calendar` weekday values: 1 = Sunday … 7 = Saturday.
    var rawValues: Set<Int>

    static let weekdays = WeekdaySet(rawValues: [2, 3, 4, 5, 6])
    static let everyDay = WeekdaySet(rawValues: Set(1...7))

    func contains(_ weekday: Int) -> Bool {
        rawValues.contains(weekday)
    }

    mutating func toggle(_ weekday: Int) {
        if rawValues.contains(weekday) {
            guard rawValues.count > 1 else { return }
            rawValues.remove(weekday)
        } else {
            rawValues.insert(weekday)
        }
    }
}

struct ScheduleSettings: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var start: TimeOfDay
    var stop: TimeOfDay
    /// Each day's start and stop shift independently by up to this many minutes.
    var thresholdMinutes: Int
    var activeWeekdays: WeekdaySet

    static let `default` = ScheduleSettings(
        isEnabled: true,
        start: .morning,
        stop: .evening,
        thresholdMinutes: 15,
        activeWeekdays: .weekdays
    )

    var thresholdRange: ClosedRange<Int> {
        -thresholdMinutes...thresholdMinutes
    }
}

struct DayOffsets: Codable, Equatable, Sendable {
    var dayStamp: String
    var startMinutes: Int
    var stopMinutes: Int
}

struct DailyWindow: Equatable, Sendable {
    var dayStamp: String
    var start: Date
    var end: Date
    var startOffsetMinutes: Int
    var stopOffsetMinutes: Int
    var isOvernight: Bool

    func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }
}

struct OffsetCache: Codable, Equatable, Sendable {
    var byDay: [String: DayOffsets] = [:]

    mutating func prune(keeping stamps: Set<String>) {
        byDay = byDay.filter { stamps.contains($0.key) }
    }
}

enum ScheduleEvaluation: Equatable, Sendable {
    case alwaysOn
    case inactiveDay
    case waiting(until: Date, window: DailyWindow)
    case active(window: DailyWindow)
    case finished(window: DailyWindow)

    var isJigglingAllowed: Bool {
        switch self {
        case .alwaysOn, .active: true
        case .inactiveDay, .waiting, .finished: false
        }
    }
}
