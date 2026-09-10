import AppKit
import os

/// Menu-bar (agent) apps don’t get a usable Settings menu, so `SettingsLink` does nothing.
/// This activates the app, shows our Settings window, then hides the Dock icon again when it closes.
@MainActor
enum SettingsPresenter {
    private static var closeObserver: NSObjectProtocol?

    static func reveal() {
        AppLog.app.info("Presenting settings window")
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        watchForSettingsCloseIfNeeded()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            bringSettingsToFront()
            try? await Task.sleep(for: .milliseconds(150))
            bringSettingsToFront()
        }
    }

    private static func bringSettingsToFront() {
        for window in NSApp.windows where isSettingsWindow(window) {
            window.collectionBehavior.insert(.moveToActiveSpace)
            window.makeKeyAndOrderFront(nil)
        }
    }

    private static func watchForSettingsCloseIfNeeded() {
        guard closeObserver == nil else { return }
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { notification in
            let window = notification.object as? NSWindow
            Task { @MainActor in
                restoreAccessoryIfNeeded(closing: window)
            }
        }
    }

    private static func restoreAccessoryIfNeeded(closing: NSWindow?) {
        let stillShowingSettings = NSApp.windows.contains { window in
            window !== closing && isSettingsWindow(window)
        }
        if !stillShowingSettings {
            AppLog.app.info("Settings closed; returning to menu bar only")
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private static func isSettingsWindow(_ window: NSWindow) -> Bool {
        if window.identifier?.rawValue == "settings" { return true }
        if window.identifier?.rawValue == "com_apple_SwiftUI_Settings_window" { return true }
        if window is NSPanel { return false }
        return window.title == "Settings"
            && window.styleMask.contains(.titled)
            && window.styleMask.contains(.closable)
    }
}
