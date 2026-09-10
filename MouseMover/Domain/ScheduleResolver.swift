import Foundation
import os

enum ScheduleResolver {
    static func dayStamp(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func offsets(
        for dayStamp: String,
        settings: ScheduleSettings,
        cache: inout OffsetCache,
        generator: inout some RandomNumberGenerator
    ) -> DayOffsets {
        if let stored = cache.byDay[dayStamp] {
            AppLog.schedule.debug("Reusing offsets for \(dayStamp, privacy: .public) start=\(stored.startMinutes)m stop=\(stored.stopMinutes)m")
            return stored
        }

        let created = DayOffsets(
            dayStamp: dayStamp,
            startMinutes: Int.random(in: settings.thresholdRange, using: &generator),
            stopMinutes: Int.random(in: settings.thresholdRange, using: &generator)
        )
        cache.byDay[dayStamp] = created
        AppLog.schedule.info("Rolled offsets for \(created.dayStamp, privacy: .public) start=\(created.startMinutes)m stop=\(created.stopMinutes)m (threshold ±\(settings.thresholdMinutes)m)")
        return created
    }

    static func window(
        on day: Date,
        settings: ScheduleSettings,
        offsets: DayOffsets,
        calendar: Calendar
    ) -> DailyWindow {
        let dayStart = calendar.startOfDay(for: day)
        let start = calendar.date(
            byAdding: .minute,
            value: settings.start.minutesSinceMidnight + offsets.startMinutes,
            to: dayStart
        ) ?? dayStart

        var end = calendar.date(
            byAdding: .minute,
            value: settings.stop.minutesSinceMidnight + offsets.stopMinutes,
            to: dayStart
        ) ?? dayStart

        let wrapsOvernight = settings.stop.minutesSinceMidnight <= settings.start.minutesSinceMidnight
        if wrapsOvernight {
            end = calendar.date(byAdding: .day, value: 1, to: end) ?? end.addingTimeInterval(24 * 60 * 60)
        }

        if end <= start {
            end = start.addingTimeInterval(15 * 60)
        }

        return DailyWindow(
            dayStamp: offsets.dayStamp,
            start: start,
            end: end,
            startOffsetMinutes: offsets.startMinutes,
            stopOffsetMinutes: offsets.stopMinutes,
            isOvernight: wrapsOvernight
        )
    }

    static func evaluate(
        at date: Date,
        settings: ScheduleSettings,
        cache: inout OffsetCache,
        calendar: Calendar = .current,
        generator: inout some RandomNumberGenerator
    ) -> (ScheduleEvaluation, DailyWindow?) {
        let todayStamp = dayStamp(for: date, calendar: calendar)
        let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: date)
        let yesterdayStamp = yesterdayDate.map { dayStamp(for: $0, calendar: calendar) }

        defer {
            var keep = Set([todayStamp])
            if let yesterdayStamp { keep.insert(yesterdayStamp) }
            cache.prune(keeping: keep)
        }

        guard settings.isEnabled else {
            return (.alwaysOn, nil)
        }

        if let yesterdayDate, let yesterdayStamp {
            let yesterdayOffsets = offsets(
                for: yesterdayStamp,
                settings: settings,
                cache: &cache,
                generator: &generator
            )
            let yesterdayWindow = window(
                on: yesterdayDate,
                settings: settings,
                offsets: yesterdayOffsets,
                calendar: calendar
            )
            if yesterdayWindow.contains(date), isActiveWeekday(yesterdayDate, settings: settings, calendar: calendar) {
                return (.active(window: yesterdayWindow), yesterdayWindow)
            }
        }

        let todayOffsets = offsets(for: todayStamp, settings: settings, cache: &cache, generator: &generator)
        let todayWindow = window(on: date, settings: settings, offsets: todayOffsets, calendar: calendar)

        guard isActiveWeekday(date, settings: settings, calendar: calendar) else {
            return (.inactiveDay, todayWindow)
        }

        if date < todayWindow.start {
            return (.waiting(until: todayWindow.start, window: todayWindow), todayWindow)
        }
        if todayWindow.contains(date) {
            return (.active(window: todayWindow), todayWindow)
        }
        return (.finished(window: todayWindow), todayWindow)
    }

    static func isActiveWeekday(_ date: Date, settings: ScheduleSettings, calendar: Calendar) -> Bool {
        settings.activeWeekdays.contains(calendar.component(.weekday, from: date))
    }

    static func rerollToday(
        at date: Date,
        settings: ScheduleSettings,
        cache: inout OffsetCache,
        calendar: Calendar = .current,
        generator: inout some RandomNumberGenerator
    ) -> DailyWindow {
        let stamp = dayStamp(for: date, calendar: calendar)
        AppLog.schedule.info("Rerolling window for \(stamp, privacy: .public)")
        cache.byDay[stamp] = nil
        let offsets = offsets(for: stamp, settings: settings, cache: &cache, generator: &generator)
        let window = window(on: date, settings: settings, offsets: offsets, calendar: calendar)
        AppLog.schedule.info("New window \(window.logDescription, privacy: .public)")
        return window
    }
}
