import Foundation
import os

enum SettingsStore {
    private static let settingsKey = "app.settings.v1"
    private static let offsetsKey = "app.schedule.offsets.v1"
    private static let firstLaunchKey = "app.hasCompletedFirstLaunch"

    static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
            AppLog.settings.info("No saved settings; using defaults")
            return .default
        }
        do {
            let settings = try JSONDecoder().decode(AppSettings.self, from: data)
            AppLog.settings.info("Loaded settings \(settings.logDescription, privacy: .public)")
            return settings
        } catch {
            AppLog.settings.error("Failed to decode settings: \(error.localizedDescription, privacy: .public)")
            return .default
        }
    }

    static func saveSettings(_ settings: AppSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
            AppLog.settings.debug("Saved settings")
        } catch {
            AppLog.settings.error("Failed to save settings: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func loadOffsets() -> OffsetCache {
        guard let data = UserDefaults.standard.data(forKey: offsetsKey) else {
            AppLog.schedule.info("No stored schedule offsets")
            return OffsetCache()
        }
        do {
            let cache = try JSONDecoder().decode(OffsetCache.self, from: data)
            AppLog.schedule.info("Loaded offsets for \(cache.byDay.count) day(s)")
            return cache
        } catch {
            AppLog.schedule.error("Failed to decode offsets: \(error.localizedDescription, privacy: .public)")
            return OffsetCache()
        }
    }

    static func saveOffsets(_ cache: OffsetCache) {
        do {
            let data = try JSONEncoder().encode(cache)
            UserDefaults.standard.set(data, forKey: offsetsKey)
            AppLog.schedule.debug("Saved offsets for \(cache.byDay.count) day(s)")
        } catch {
            AppLog.schedule.error("Failed to save offsets: \(error.localizedDescription, privacy: .public)")
        }
    }

    static var hasCompletedFirstLaunch: Bool {
        get { UserDefaults.standard.bool(forKey: firstLaunchKey) }
        set {
            if newValue != UserDefaults.standard.bool(forKey: firstLaunchKey) {
                AppLog.app.info("First launch completed=\(newValue)")
            }
            UserDefaults.standard.set(newValue, forKey: firstLaunchKey)
        }
    }
}
