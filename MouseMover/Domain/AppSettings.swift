import Foundation

struct AppSettings: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var launchAtLogin: Bool
    var movement: MovementSettings
    var schedule: ScheduleSettings

    static let `default` = AppSettings(
        isEnabled: false,
        launchAtLogin: false,
        movement: .default,
        schedule: .default
    )
}
