import CoreGraphics
import Foundation
import Testing
@testable import MouseMover

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct ScheduleResolverTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test func zeroThresholdKeepsExactTimes() {
        var settings = ScheduleSettings.default
        settings.thresholdMinutes = 0
        settings.start = TimeOfDay(hour: 9, minute: 0)
        settings.stop = TimeOfDay(hour: 17, minute: 0)
        var cache = OffsetCache()
        var generator = SeededGenerator(seed: 1)
        let noon = date(2026, 9, 8, 12, 0)

        let (evaluation, window) = ScheduleResolver.evaluate(
            at: noon,
            settings: settings,
            cache: &cache,
            calendar: calendar,
            generator: &generator
        )

        guard case .active(let activeWindow) = evaluation, let window else {
            Issue.record("Expected an active window")
            return
        }
        #expect(activeWindow.start == window.start)
        #expect(calendar.component(.hour, from: window.start) == 9)
        #expect(calendar.component(.minute, from: window.start) == 0)
        #expect(calendar.component(.hour, from: window.end) == 17)
        #expect(calendar.component(.minute, from: window.end) == 0)
    }

    @Test func thresholdStaysInsideConfiguredRange() throws {
        var settings = ScheduleSettings.default
        settings.thresholdMinutes = 12
        settings.start = TimeOfDay(hour: 9, minute: 0)
        settings.stop = TimeOfDay(hour: 17, minute: 0)
        var cache = OffsetCache()
        var generator = SeededGenerator(seed: 42)
        let noon = date(2026, 9, 8, 12, 0)

        let (_, resolved) = ScheduleResolver.evaluate(
            at: noon,
            settings: settings,
            cache: &cache,
            calendar: calendar,
            generator: &generator
        )

        let window = try #require(resolved)
        #expect((-12...12).contains(window.startOffsetMinutes))
        #expect((-12...12).contains(window.stopOffsetMinutes))
    }

    @Test func sameDayReusesPersistedOffsets() {
        var settings = ScheduleSettings.default
        settings.thresholdMinutes = 20
        var cache = OffsetCache()
        var generator = SeededGenerator(seed: 7)
        let morning = date(2026, 9, 8, 8, 0)

        let (_, first) = ScheduleResolver.evaluate(
            at: morning,
            settings: settings,
            cache: &cache,
            calendar: calendar,
            generator: &generator
        )
        var laterGenerator = SeededGenerator(seed: 99)
        let (_, second) = ScheduleResolver.evaluate(
            at: date(2026, 9, 8, 15, 0),
            settings: settings,
            cache: &cache,
            calendar: calendar,
            generator: &laterGenerator
        )

        #expect(first == second)
    }

    @Test func overnightWindowSpansMidnight() throws {
        var settings = ScheduleSettings.default
        settings.start = TimeOfDay(hour: 22, minute: 0)
        settings.stop = TimeOfDay(hour: 6, minute: 0)
        settings.thresholdMinutes = 0
        settings.activeWeekdays = .everyDay
        var cache = OffsetCache()
        var generator = SeededGenerator(seed: 3)

        let late = date(2026, 9, 8, 23, 30)
        let (evening, eveningWindow) = ScheduleResolver.evaluate(
            at: late,
            settings: settings,
            cache: &cache,
            calendar: calendar,
            generator: &generator
        )
        let early = date(2026, 9, 9, 3, 0)
        let (night, _) = ScheduleResolver.evaluate(
            at: early,
            settings: settings,
            cache: &cache,
            calendar: calendar,
            generator: &generator
        )

        #expect(evening.isJigglingAllowed)
        #expect(night.isJigglingAllowed)
        let window = try #require(eveningWindow)
        #expect(window.end > window.start)
        #expect(window.contains(early))
    }

    @Test func disabledScheduleIsAlwaysOn() {
        var settings = ScheduleSettings.default
        settings.isEnabled = false
        var cache = OffsetCache()
        var generator = SeededGenerator(seed: 1)
        let (evaluation, window) = ScheduleResolver.evaluate(
            at: date(2026, 9, 8, 3, 0),
            settings: settings,
            cache: &cache,
            calendar: calendar,
            generator: &generator
        )
        #expect(evaluation == .alwaysOn)
        #expect(window == nil)
    }

    @Test func weekendIsInactiveWhenOnlyWeekdaysAreSelected() {
        var settings = ScheduleSettings.default
        settings.thresholdMinutes = 0
        var cache = OffsetCache()
        var generator = SeededGenerator(seed: 3)
        let saturday = date(2026, 9, 5, 12, 0)

        let (evaluation, _) = ScheduleResolver.evaluate(
            at: saturday,
            settings: settings,
            cache: &cache,
            calendar: calendar,
            generator: &generator
        )

        #expect(evaluation == .inactiveDay)
    }
}

struct MovementPathTests {
    @Test func restoredPathEndsAtOrigin() throws {
        var generator = SeededGenerator(seed: 11)
        let origin = CGPoint(x: 100, y: 200)
        for pattern in MovementPattern.allCases {
            let path = MovementPath.points(
                origin: origin,
                distance: 10,
                steps: 16,
                pattern: pattern,
                restore: true,
                generator: &generator
            )
            let last = try #require(path.last)
            #expect(abs(last.x - origin.x) < 0.001)
            #expect(abs(last.y - origin.y) < 0.001)
        }
    }

    @Test func jitterStaysWithinPercent() {
        var settings = MovementSettings.default
        settings.distancePixels = 10
        settings.distanceJitterPercent = 20
        var generator = SeededGenerator(seed: 5)
        for _ in 0..<50 {
            let distance = settings.nextDistance(using: &generator)
            #expect((8...12).contains(distance))
        }
    }
}
