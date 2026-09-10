import Foundation

struct TimeOfDay: Codable, Equatable, Hashable, Sendable {
    var hour: Int
    var minute: Int

    static let morning = TimeOfDay(hour: 9, minute: 0)
    static let evening = TimeOfDay(hour: 17, minute: 0)

    var minutesSinceMidnight: Int {
        hour * 60 + minute
    }

    init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    func date(on day: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutesSinceMidnight, to: start) ?? day
    }

    func formatted(locale: Locale = .current) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let reference = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: hour, minute: minute)) ?? .now
        return formatter.string(from: reference)
    }
}
