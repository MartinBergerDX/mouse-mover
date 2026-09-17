import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section {
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { model.settings.launchAtLogin },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )
                if let loginItemError = model.loginItemError {
                    Text(loginItemError)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            } footer: {
                Text("Starts Mouse Mover when you log in to this Mac. macOS may ask you to confirm the first time.")
            }

            Section {
                if model.isAccessibilityTrusted {
                    Label("Accessibility access is granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    PermissionBanner()
                }
            } header: {
                Text("Permissions")
            }

            Section {
                Toggle(
                    "Enabled",
                    isOn: Binding(
                        get: { model.settings.isEnabled },
                        set: { model.setEnabled($0) }
                    )
                )
            } header: {
                Text("Status")
            } footer: {
                Text(statusFooter)
            }

            Section {
                LabeledContent("Shortcut") {
                    Text("Hold \(QuitHotkeyService.displayName)")
                        .foregroundStyle(.secondary)
                        .monospaced()
                }
                FineSlider(
                    title: "Hold duration",
                    value: $model.settings.quitHotkeyHoldSeconds,
                    range: AppSettings.quitHotkeyHoldRange,
                    step: 0.1,
                    format: "%.1f s",
                    help: "How long you must hold the shortcut before Mouse Mover quits."
                )
            } header: {
                Text("Panic quit")
            } footer: {
                Text("Works in any app, including while screensharing. A longer hold is harder to trigger by accident.")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            model.refreshLoginItemStatus()
        }
    }

    private var statusFooter: String {
        switch model.phase {
        case .jiggling: "Currently jiggling the pointer."
        case .waiting(let until): "Waiting until \(until.formatted(date: .omitted, time: .shortened))."
        case .pausedForUser: "Paused because the mouse or keyboard was just used."
        case .waitingForIdle(let until): "On. Next jiggle at \(until.formatted(date: .omitted, time: .standard)) if the Mac stays idle."
        case .needsPermission: "Waiting for Accessibility permission."
        case .inactiveDay: "Today is outside the selected weekdays."
        case .finishedForToday: "Today’s window has already ended."
        case .off: "The mover is turned off."
        }
    }
}
