import Foundation

struct AppSettings: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var launchAtLogin: Bool
    var movement: MovementSettings
    var schedule: ScheduleSettings
    /// Seconds Control-Option-Command-Q must be held before the app quits.
    var quitHotkeyHoldSeconds: Double

    nonisolated static let quitHotkeyHoldRange = 0.1...5.0
    nonisolated static let defaultQuitHotkeyHoldSeconds = 0.6

    static let `default` = AppSettings(
        isEnabled: false,
        launchAtLogin: false,
        movement: .default,
        schedule: .default,
        quitHotkeyHoldSeconds: defaultQuitHotkeyHoldSeconds
    )

    enum CodingKeys: String, CodingKey {
        case isEnabled, launchAtLogin, movement, schedule, quitHotkeyHoldSeconds
    }

    init(
        isEnabled: Bool,
        launchAtLogin: Bool,
        movement: MovementSettings,
        schedule: ScheduleSettings,
        quitHotkeyHoldSeconds: Double
    ) {
        self.isEnabled = isEnabled
        self.launchAtLogin = launchAtLogin
        self.movement = movement
        self.schedule = schedule
        self.quitHotkeyHoldSeconds = Self.clampedHold(quitHotkeyHoldSeconds)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        launchAtLogin = try container.decode(Bool.self, forKey: .launchAtLogin)
        movement = try container.decode(MovementSettings.self, forKey: .movement)
        schedule = try container.decode(ScheduleSettings.self, forKey: .schedule)
        quitHotkeyHoldSeconds = Self.clampedHold(
            try container.decodeIfPresent(Double.self, forKey: .quitHotkeyHoldSeconds)
                ?? Self.defaultQuitHotkeyHoldSeconds
        )
    }

    private static func clampedHold(_ seconds: Double) -> Double {
        min(max(seconds, quitHotkeyHoldRange.lowerBound), quitHotkeyHoldRange.upperBound)
    }
}
