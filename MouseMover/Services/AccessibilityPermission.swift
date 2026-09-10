import ApplicationServices
import AppKit
import Foundation
import os

enum AccessibilityPermission {
    static var isTrusted: Bool {
        AXIsProcessTrustedWithOptions(promptOptions(prompt: false))
    }

    static var runningAppURL: URL {
        Bundle.main.bundleURL
    }

    static func request() {
        logDiagnostics(reason: "prompt")
        let trusted = AXIsProcessTrustedWithOptions(promptOptions(prompt: true))
        AppLog.permission.info("Prompt result trusted=\(trusted)")
    }

    static func openSystemSettings() {
        AppLog.permission.info("Opening System Settings → Accessibility")
        let urls = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
        ]
        for string in urls {
            if let url = URL(string: string), NSWorkspace.shared.open(url) {
                AppLog.permission.info("Opened \(string, privacy: .public)")
                return
            }
        }
        AppLog.permission.error("Could not open System Settings for Accessibility")
    }

    static func logDiagnostics(reason: String) {
        let trusted = isTrusted
        let legacyTrusted = AXIsProcessTrusted()
        AppLog.permission.info(
            "Accessibility \(reason, privacy: .public) trusted=\(trusted) legacy=\(legacyTrusted) id=\(Bundle.main.bundleIdentifier ?? "nil", privacy: .public) app=\(runningAppURL.path, privacy: .public) executable=\(Bundle.main.executablePath ?? "nil", privacy: .public)"
        )
    }

    private static func promptOptions(prompt: Bool) -> CFDictionary {
        // kAXTrustedCheckOptionPrompt is a mutable CFString global; Swift 6
        // won't let us touch it from this isolation. The key's string value is stable.
        ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
    }
}
