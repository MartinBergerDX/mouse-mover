import AppKit
import Carbon
import Foundation
import os

/// System-wide panic quit. Hold Control-Option-Command-Q so a tap cannot fire it.
///
/// Uses a Carbon hot key so other apps do not receive the Q, and so it works
/// even when Mouse Mover is an accessory (no Dock, not key).
nonisolated
final class QuitHotkeyService: @unchecked Sendable {
    static let shared = QuitHotkeyService()

    static let displayName = "⌃⌥⌘Q"

    private static let signature: OSType = 0x4D4F_5652 // "MOVR"
    private static let hotKeyID: UInt32 = 1

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var didInstall = false
    private let lock = NSLock()
    private var holdTask: Task<Void, Never>?
    private var holdSeconds = AppSettings.defaultQuitHotkeyHoldSeconds

    private init() {}

    func start() {
        DispatchQueue.main.async { [weak self] in
            self?.installOnMain()
        }
    }

    func setHoldSeconds(_ seconds: Double) {
        let clamped = min(
            max(seconds, AppSettings.quitHotkeyHoldRange.lowerBound),
            AppSettings.quitHotkeyHoldRange.upperBound
        )
        lock.lock()
        holdSeconds = clamped
        lock.unlock()
    }

    fileprivate func notePressed() {
        lock.lock()
        let seconds = holdSeconds
        holdTask?.cancel()
        let task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            AppLog.app.info("Quit hotkey held \(seconds, format: .fixed(precision: 1))s; terminating")
            await MainActor.run {
                NSApp.terminate(nil)
            }
            self?.clearHoldTask()
        }
        holdTask = task
        lock.unlock()
    }

    fileprivate func noteReleased() {
        clearHoldTask()
    }

    private func clearHoldTask() {
        lock.lock()
        holdTask?.cancel()
        holdTask = nil
        lock.unlock()
    }

    private func installOnMain() {
        guard !didInstall else { return }
        didInstall = true

        var hotKeyID = EventHotKeyID(signature: Self.signature, id: Self.hotKeyID)
        var hotKeyRef: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_Q),
            UInt32(controlKey | optionKey | cmdKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        self.hotKeyRef = hotKeyRef
        guard registerStatus == noErr else {
            AppLog.app.error("Quit hotkey could not be registered (\(registerStatus))")
            return
        }

        var specs = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                let service = Unmanaged<QuitHotkeyService>.fromOpaque(userData).takeUnretainedValue()
                switch GetEventKind(event) {
                case UInt32(kEventHotKeyPressed):
                    service.notePressed()
                case UInt32(kEventHotKeyReleased):
                    service.noteReleased()
                default:
                    break
                }
                return noErr
            },
            2,
            &specs,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        guard handlerStatus == noErr else {
            AppLog.app.error("Quit hotkey handler could not be installed (\(handlerStatus))")
            return
        }

        AppLog.app.info("Quit hotkey registered (hold \(QuitHotkeyService.displayName, privacy: .public))")
    }
}
