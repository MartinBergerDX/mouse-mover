import AppKit
import Foundation
import os

enum EnginePhase: Equatable, Sendable {
    case off
    case needsPermission
    case inactiveDay
    case waiting(until: Date)
    case waitingForIdle(until: Date)
    case pausedForUser
    case jiggling
    case finishedForToday

    var menuBarImage: String {
        switch self {
        case .jiggling: "MenuBarFruitFill"
        default: "MenuBarFruit"
        }
    }

    var isVisiblyActive: Bool {
        self == .jiggling || self == .pausedForUser
    }
}

final class JiggleEngine {
    var onPhaseChange: ((EnginePhase) -> Void)?

    private(set) var phase: EnginePhase = .off
    private(set) var todaysWindow: DailyWindow?

    private var generator = SystemRandomNumberGenerator()
    private let pointerMonitor = PointerActivityMonitor()
    private var didStartMonitor = false

    func resetRestingPoint() {
        AppLog.engine.debug("Reset user-motion timer")
        pointerMonitor.reset()
    }

    func runOnce(_ settings: MovementSettings) async {
        guard AccessibilityPermission.isTrusted else {
            AppLog.movement.warning("Preview skipped; Accessibility is not granted")
            return
        }
        AppLog.movement.info("Preview jiggle")
        await performJiggle(settings)
    }

    func tick(settings: AppSettings, cache: inout OffsetCache) async {
        startMonitorIfNeeded()

        let (evaluation, window) = ScheduleResolver.evaluate(
            at: .now,
            settings: settings.schedule,
            cache: &cache,
            generator: &generator
        )
        if let window, window != todaysWindow {
            AppLog.schedule.info("Window \(window.logDescription, privacy: .public)")
            todaysWindow = window
        } else if window != nil {
            todaysWindow = window
        }

        guard settings.isEnabled else {
            applyPhase(.off)
            try? await Task.sleep(for: .milliseconds(400))
            return
        }

        guard AccessibilityPermission.isTrusted else {
            applyPhase(.needsPermission)
            try? await Task.sleep(for: .seconds(1))
            return
        }

        switch evaluation {
        case .inactiveDay:
            applyPhase(.inactiveDay)
            try? await Task.sleep(for: .seconds(1))
        case .waiting(let until, _):
            applyPhase(.waiting(until: until))
            try? await Task.sleep(for: .seconds(1))
        case .finished:
            applyPhase(.finishedForToday)
            try? await Task.sleep(for: .seconds(1))
        case .alwaysOn, .active:
            let interval = settings.movement.nextInterval(using: &generator)
            if settings.movement.pauseWhileUsingPointer {
                await waitForIdleInterval(interval)
                if Task.isCancelled { return }
            }
            applyPhase(.jiggling)
            await performJiggle(settings.movement)
            if !settings.movement.pauseWhileUsingPointer {
                AppLog.engine.debug("Next jiggle in \(self.intervalLog(interval), privacy: .public)")
                try? await Task.sleep(for: interval)
            }
        }
    }

    private func startMonitorIfNeeded() {
        guard !didStartMonitor else { return }
        didStartMonitor = true
        pointerMonitor.start()
    }

    private func performJiggle(_ settings: MovementSettings) async {
        pointerMonitor.beginSynthetic()
        var rng = generator
        await MouseSynthesizer.jiggle(
            settings,
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
            generator: &rng
        )
        generator = rng
        try? await Task.sleep(for: .milliseconds(80))
        pointerMonitor.endSynthetic()
    }

    /// Wait until there has been no real mouse or keyboard input for `interval`.
    /// Any real user input restarts the countdown.
    private func waitForIdleInterval(_ interval: Duration) async {
        let seconds = durationSeconds(interval)
        var deadline = Date.now.addingTimeInterval(seconds)
        var wasUsingInput = false
        applyPhase(.waitingForIdle(until: deadline))
        AppLog.engine.info("Idle interval \(self.intervalLog(interval), privacy: .public) started")

        while !Task.isCancelled {
            let active = pointerMonitor.secondsSinceUserActivity < 0.25
            if active {
                deadline = Date.now.addingTimeInterval(seconds)
                if !wasUsingInput {
                    AppLog.engine.info("Idle interval reset; user input in progress")
                }
                wasUsingInput = true
                applyPhase(.pausedForUser)
            } else {
                if wasUsingInput {
                    deadline = Date.now.addingTimeInterval(seconds)
                    AppLog.engine.info("Input idle; idle interval restarted")
                }
                wasUsingInput = false
                applyPhase(.waitingForIdle(until: deadline))
                if Date.now >= deadline {
                    AppLog.engine.info("Idle interval elapsed; no user input")
                    return
                }
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    private func applyPhase(_ newPhase: EnginePhase) {
        if phase != newPhase {
            AppLog.engine.info("Phase \(self.phase.logDescription, privacy: .public) → \(newPhase.logDescription, privacy: .public)")
            phase = newPhase
            onPhaseChange?(newPhase)
        }
    }

    private func durationSeconds(_ interval: Duration) -> TimeInterval {
        Double(interval.components.seconds)
            + Double(interval.components.attoseconds) / 1_000_000_000_000_000_000
    }

    private func intervalLog(_ interval: Duration) -> String {
        let seconds = Double(interval.components.seconds)
            + Double(interval.components.attoseconds) / 1_000_000_000_000_000_000
        return String(format: "%.1fs", seconds)
    }
}
