import AppKit
import os
import SwiftUI

struct MenuBarRootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            statusBlock
            if !model.isAccessibilityTrusted {
                PermissionBanner()
            }
            Divider()
            HStack {
                Button {
                    openAppSettings()
                } label: {
                    Label("Settings…", systemImage: "gear")
                }
                .keyboardShortcut(",", modifiers: .command)
                Spacer()
                Button("Quit") {
                    AppLog.app.info("Quit requested")
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
        .padding(16)
        .frame(width: 340)
        .onAppear {
            if !SettingsStore.hasCompletedFirstLaunch {
                AppLog.app.info("First launch; opening settings")
                SettingsStore.hasCompletedFirstLaunch = true
                openAppSettings()
            }
        }
    }

    private func openAppSettings() {
        AppLog.app.info("Settings button pressed")
        SettingsPresenter.reveal()
        openWindow(id: "settings")
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            dismiss()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Mouse Mover")
                    .font(.headline)
                Text(statusTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle(
                "Enabled",
                isOn: Binding(
                    get: { model.settings.isEnabled },
                    set: { model.setEnabled($0) }
                )
            )
            .toggleStyle(.switch)
            .labelsHidden()
            .accessibilityLabel("Enabled")
        }
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(statusDetail, systemImage: statusSymbol)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let window = model.todaysWindow, model.settings.schedule.isEnabled {
                HStack {
                    Text("Today")
                    Spacer()
                    Text(window.start, format: .dateTime.hour().minute())
                    Text("–")
                    Text(window.end, format: .dateTime.hour().minute())
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

                HStack {
                    OffsetLabel(minutes: window.startOffsetMinutes)
                    Text("start")
                    Spacer()
                    OffsetLabel(minutes: window.stopOffsetMinutes)
                    Text("stop")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
    }

    private var statusTitle: String {
        switch model.phase {
        case .off: "Off"
        case .needsPermission: "Needs permission"
        case .inactiveDay: "Idle today"
        case .waiting(let until): "Starts \(until.formatted(date: .omitted, time: .shortened))"
        case .waitingForIdle(let until): "Next jiggle \(until.formatted(date: .omitted, time: .standard))"
        case .pausedForUser: "Paused while you type or move"
        case .jiggling: "Jiggling"
        case .finishedForToday: "Done for today"
        }
    }

    private var statusDetail: String {
        let movement = model.settings.movement
        switch model.phase {
        case .jiggling:
            return "Every \(formatSeconds(movement.intervalSeconds)), \(Int(movement.distancePixels.rounded())) px \(movement.pattern.title.lowercased())"
        case .pausedForUser:
            return "Mouse or keyboard is in use. The idle timer restarts when you stop."
        case .waitingForIdle(let until):
            return "On. Jiggles after the Mac stays idle until \(until.formatted(date: .omitted, time: .standard))."
        case .waiting:
            return "Armed. The pointer stays still until today’s window opens."
        case .finishedForToday:
            return "Today’s window has closed. It will roll new times tomorrow."
        case .inactiveDay:
            return "This weekday is not in the schedule."
        case .needsPermission:
            return "Grant Accessibility access to start moving the pointer."
        case .off:
            return "Turn it on to keep the pointer active."
        }
    }

    private var statusSymbol: String {
        switch model.phase {
        case .jiggling: "cursorarrow.motionlines"
        case .pausedForUser: "pause.fill"
        case .waiting, .waitingForIdle: "clock"
        case .needsPermission: "hand.raised"
        case .off: "moon.zzz"
        case .inactiveDay, .finishedForToday: "calendar"
        }
    }

    private func formatSeconds(_ value: Double) -> String {
        if value < 10 {
            String(format: "%.1fs", value)
        } else {
            String(format: "%.0fs", value)
        }
    }
}
