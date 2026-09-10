import AppKit
import CoreGraphics
import Foundation
import IOKit.hid
import os

/// User-activity detection that does not rely on Input Monitoring.
///
/// Default actor isolation is MainActor for this target; this type must stay
/// `nonisolated` because the event-tap callback runs outside the Swift executor.
nonisolated
final class PointerActivityMonitor: @unchecked Sendable {
    private static let syntheticMarker: Int64 = 0x4D4F_5652 // "MOVR"

    private static let pointerEventMask: CGEventMask = bit(.mouseMoved)
        | bit(.leftMouseDragged)
        | bit(.rightMouseDragged)
        | bit(.otherMouseDragged)
        | bit(.leftMouseDown)
        | bit(.rightMouseDown)
        | bit(.otherMouseDown)
        | bit(.scrollWheel)

    private static func bit(_ type: CGEventType) -> CGEventMask {
        let shift = UInt64(type.rawValue)
        guard shift < 64 else { return 0 }
        return (1 as CGEventMask) << shift
    }

    private let lock = NSLock()
    private var lastActivity = Date.distantPast
    private var lastPolledLocation: NSPoint?
    private var ignoringSynthetic = false
    private var loggedFirstTapEvent = false
    private var didStart = false

    private var locationTimer: Timer?
    private var tap: CFMachPort?
    private var tapSource: CFRunLoopSource?

    var lastUserActivity: Date {
        lock.lock()
        defer { lock.unlock() }
        return lastActivity
    }

    var secondsSinceUserActivity: TimeInterval {
        Date.now.timeIntervalSince(lastUserActivity)
    }

    var isIgnoringSynthetic: Bool {
        lock.lock()
        defer { lock.unlock() }
        return ignoringSynthetic
    }

    static var syntheticEventMarker: Int64 { syntheticMarker }

    func start() {
        DispatchQueue.main.async { [weak self] in
            self?.startOnMain()
        }
    }

    func beginSynthetic() {
        lock.lock()
        ignoringSynthetic = true
        lock.unlock()
    }

    func endSynthetic() {
        lock.lock()
        ignoringSynthetic = false
        lastPolledLocation = NSEvent.mouseLocation
        lock.unlock()
    }

    func reset() {
        lock.lock()
        lastActivity = .distantPast
        lastPolledLocation = NSEvent.mouseLocation
        lock.unlock()
    }

    func noteUserActivity(source: String, detail: String = "") {
        lock.lock()
        let ignoring = ignoringSynthetic
        let previous = lastActivity
        if !ignoring {
            lastActivity = .now
        }
        lock.unlock()
        guard !ignoring else { return }
        let gap = Date.now.timeIntervalSince(previous)
        if gap > 1 {
            AppLog.engine.info("Pointer interrupt (\(source, privacy: .public))\(detail, privacy: .public); resetting idle interval")
        }
    }

    func handleTap(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
                AppLog.engine.info("Re-enabled pointer event tap")
            }
            return
        }

        let sourceID = event.getIntegerValueField(.eventSourceStateID)
        let userData = event.getIntegerValueField(.eventSourceUserData)
        if userData == Self.syntheticMarker {
            return
        }

        lock.lock()
        let shouldLogFirst = !loggedFirstTapEvent
        if shouldLogFirst { loggedFirstTapEvent = true }
        let ignoring = ignoringSynthetic
        lock.unlock()

        if shouldLogFirst {
            AppLog.engine.info(
                "First tap event \(type.logName, privacy: .public) sourceID=\(sourceID) userData=\(userData)"
            )
        }

        guard !ignoring else { return }

        if sourceID == 0 || type != .mouseMoved {
            noteUserActivity(source: "tap.\(type.logName)")
        }
    }

    private func startOnMain() {
        guard !didStart else { return }
        didStart = true
        startLocationPolling()
        installEventTap()
        logListenPermission()
    }

    private func startLocationPolling() {
        guard locationTimer == nil else { return }
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.sampleLocation()
        }
        timer.tolerance = 0.02
        RunLoop.main.add(timer, forMode: .common)
        locationTimer = timer
        lastPolledLocation = NSEvent.mouseLocation
        AppLog.engine.info("Pointer location polling started")
    }

    private func sampleLocation() {
        lock.lock()
        let ignoring = ignoringSynthetic
        lock.unlock()
        guard !ignoring else { return }

        let location = NSEvent.mouseLocation
        lock.lock()
        let previous = lastPolledLocation
        lastPolledLocation = location
        lock.unlock()

        guard let previous else { return }
        let delta = hypot(location.x - previous.x, location.y - previous.y)
        if delta >= 2 {
            noteUserActivity(source: "position", detail: String(format: " %.0fpx", delta))
        }
    }

    private func installEventTap() {
        guard tap == nil else { return }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: Self.pointerEventMask,
            callback: { _, type, event, refcon in
                if let refcon {
                    Unmanaged<PointerActivityMonitor>
                        .fromOpaque(refcon)
                        .takeUnretainedValue()
                        .handleTap(type: type, event: event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            AppLog.engine.error("CGEvent tap could not be created; relying on location polling")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        self.tapSource = source
        let enabled = CGEvent.tapIsEnabled(tap: tap)
        AppLog.engine.info("Pointer event tap installed enabled=\(enabled)")
        if !enabled {
            AppLog.engine.error("Pointer event tap is not enabled; location polling remains active")
        }
    }

    private func logListenPermission() {
        let listen = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
        AppLog.engine.info("Input Monitoring (listen) access=\(listen.rawValue) (0=granted, 1=denied, 2=unknown)")
    }
}

extension CGEventType {
    nonisolated var logName: String {
        switch self {
        case .mouseMoved: "mouseMoved"
        case .leftMouseDragged: "leftDrag"
        case .rightMouseDragged: "rightDrag"
        case .otherMouseDragged: "otherDrag"
        case .leftMouseDown: "leftDown"
        case .rightMouseDown: "rightDown"
        case .otherMouseDown: "otherDown"
        case .scrollWheel: "scroll"
        default: "event(\(rawValue))"
        }
    }
}
