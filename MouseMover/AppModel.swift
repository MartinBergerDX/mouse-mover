import Combine
import Foundation
import os

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            SettingsStore.saveSettings(settings)
            logSettingsChange(from: oldValue, to: settings)
            if oldValue.schedule.thresholdMinutes != settings.schedule.thresholdMinutes
                || oldValue.schedule.start != settings.schedule.start
                || oldValue.schedule.stop != settings.schedule.stop {
                AppLog.schedule.info("Start/stop/threshold changed; clearing stored offsets")
                offsetCache = OffsetCache()
                seedWindow()
            }
        }
    }

    @Published var offsetCache: OffsetCache {
        didSet { SettingsStore.saveOffsets(offsetCache) }
    }

    @Published var isAccessibilityTrusted = AccessibilityPermission.isTrusted
    @Published var loginItemError: String?
    @Published var phase: EnginePhase = .off
    @Published var todaysWindow: DailyWindow?

    let engine = JiggleEngine()

    private var loop: Task<Void, Never>?
    private var permissionLoop: Task<Void, Never>?
    private var generator = SystemRandomNumberGenerator()
    private var sleepAssertion: NSObjectProtocol?

    init(startsEngine: Bool = true) {
        var loaded = SettingsStore.loadSettings()
        loaded.launchAtLogin = LoginItemService.isEnabled
        settings = loaded
        offsetCache = SettingsStore.loadOffsets()
        isAccessibilityTrusted = AccessibilityPermission.isTrusted
        engine.onPhaseChange = { [weak self] phase in
            self?.phase = phase
        }
        AppLog.app.info("Launch \(loaded.logDescription, privacy: .public)")
        AccessibilityPermission.logDiagnostics(reason: "launch")
        AppLog.loginItem.info("Launch at login \(loaded.launchAtLogin)")
        seedWindow()
        if startsEngine {
            start()
        }
        updateSleepAssertion()
    }

    func start() {
        guard loop == nil else {
            AppLog.engine.debug("Engine loop already running")
            return
        }
        AppLog.engine.info("Starting engine loop")
        loop = Task { [weak self] in
            while let self, !Task.isCancelled {
                var cache = self.offsetCache
                await self.engine.tick(settings: self.settings, cache: &cache)
                self.phase = self.engine.phase
                self.todaysWindow = self.engine.todaysWindow
                if cache != self.offsetCache {
                    self.offsetCache = cache
                }
            }
            AppLog.engine.info("Engine loop ended")
        }
        permissionLoop = Task { [weak self] in
            while let self, !Task.isCancelled {
                let trusted = AccessibilityPermission.isTrusted
                if trusted != self.isAccessibilityTrusted {
                    AppLog.permission.info("Accessibility trusted \(self.isAccessibilityTrusted) → \(trusted)")
                    self.isAccessibilityTrusted = trusted
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stop() {
        AppLog.engine.info("Stopping engine loop")
        loop?.cancel()
        permissionLoop?.cancel()
        loop = nil
        permissionLoop = nil
    }

    func setEnabled(_ enabled: Bool) {
        AppLog.app.info("Set enabled \(enabled)")
        settings.isEnabled = enabled
        if enabled, !isAccessibilityTrusted {
            AppLog.permission.info("Enabled while untrusted; requesting Accessibility")
            AccessibilityPermission.request()
        }
        engine.resetRestingPoint()
        updateSleepAssertion()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        AppLog.loginItem.info("Set launch at login \(enabled)")
        do {
            try LoginItemService.setEnabled(enabled)
            settings.launchAtLogin = LoginItemService.isEnabled
            loginItemError = nil
            AppLog.loginItem.info("Launch at login is now \(self.settings.launchAtLogin)")
        } catch {
            settings.launchAtLogin = LoginItemService.isEnabled
            loginItemError = error.localizedDescription
            AppLog.loginItem.error("Launch at login failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func refreshLoginItemStatus() {
        let enabled = LoginItemService.isEnabled
        if settings.launchAtLogin != enabled {
            AppLog.loginItem.info("Login item status refreshed \(self.settings.launchAtLogin) → \(enabled)")
        }
        settings.launchAtLogin = enabled
    }

    func rerollTodaysWindow() {
        var cache = offsetCache
        let window = ScheduleResolver.rerollToday(
            at: .now,
            settings: settings.schedule,
            cache: &cache,
            generator: &generator
        )
        offsetCache = cache
        todaysWindow = window
    }

    func previewMovement() {
        AppLog.movement.info("Preview requested (\(self.settings.movement.pattern.rawValue, privacy: .public))")
        Task { await engine.runOnce(settings.movement) }
    }

    private func seedWindow() {
        var cache = offsetCache
        let (evaluation, window) = ScheduleResolver.evaluate(
            at: .now,
            settings: settings.schedule,
            cache: &cache,
            generator: &generator
        )
        offsetCache = cache
        todaysWindow = window
        SettingsStore.saveOffsets(cache)
        if let window {
            AppLog.schedule.info("Seeded \(evaluation.logDescription, privacy: .public) \(window.logDescription, privacy: .public)")
        } else {
            AppLog.schedule.info("Seeded \(evaluation.logDescription, privacy: .public)")
        }
    }

    private func updateSleepAssertion() {
        if settings.isEnabled {
            if sleepAssertion == nil {
                sleepAssertion = ProcessInfo.processInfo.beginActivity(
                    options: .userInitiatedAllowingIdleSystemSleep,
                    reason: "Mouse Mover"
                )
                AppLog.app.info("Took idle sleep assertion")
            }
        } else if let sleepAssertion {
            ProcessInfo.processInfo.endActivity(sleepAssertion)
            self.sleepAssertion = nil
            AppLog.app.info("Released idle sleep assertion")
        }
    }

    private func logSettingsChange(from old: AppSettings, to new: AppSettings) {
        if old.schedule != new.schedule {
            AppLog.schedule.info("Schedule \(new.schedule.logDescription, privacy: .public)")
        }
        if old.movement.pattern != new.movement.pattern
            || old.movement.restorePosition != new.movement.restorePosition
            || old.movement.pauseWhileUsingPointer != new.movement.pauseWhileUsingPointer {
            AppLog.movement.info("Movement \(new.movement.logDescription, privacy: .public)")
        }
    }
}
