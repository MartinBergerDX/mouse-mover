import os
import SwiftUI

@main
struct MouseMoverApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView()
                .environmentObject(model)
        } label: {
            Image(model.phase.menuBarImage)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .accessibilityLabel(menuBarAccessibilityLabel)
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(model)
        }
        .defaultSize(width: 560, height: 640)
        .windowResizability(.contentMinSize)
        .commands {
            SettingsCommands()
        }
    }

    private var menuBarAccessibilityLabel: String {
        switch model.phase {
        case .jiggling: "Mouse Mover is jiggling"
        case .waiting: "Mouse Mover is waiting for the schedule"
        case .waitingForIdle: "Mouse Mover is on and waiting for idle"
        case .off: "Mouse Mover is off"
        default: "Mouse Mover"
        }
    }
}

private struct SettingsCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button("Settings…") {
                AppLog.app.info("Settings opened from app menu")
                SettingsPresenter.reveal()
                openWindow(id: "settings")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
