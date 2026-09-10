import AppKit
import CoreGraphics
import Foundation
import os

enum MouseSynthesizer {
    static func location() -> CGPoint {
        quartzLocation(from: NSEvent.mouseLocation)
    }

    static func move(to point: CGPoint) {
        let current = location()
        let source = CGEventSource(stateID: .hidSystemState)

        guard let event = CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            AppLog.movement.error("Could not create mouse-moved event")
            return
        }

        event.setIntegerValueField(.mouseEventDeltaX, value: Int64((point.x - current.x).rounded()))
        event.setIntegerValueField(.mouseEventDeltaY, value: Int64((point.y - current.y).rounded()))
        event.setIntegerValueField(.eventSourceUserData, value: PointerActivityMonitor.syntheticEventMarker)
        event.post(tap: .cghidEventTap)
        CGWarpMouseCursorPosition(point)
        CGAssociateMouseAndMouseCursorPosition(boolean_t(true))
    }

    static func jiggle(
        _ settings: MovementSettings,
        reduceMotion: Bool,
        generator: inout some RandomNumberGenerator
    ) async {
        let origin = location()
        let distance = CGFloat(settings.nextDistance(using: &generator))
        let steps = settings.stepCount(reduceMotion: reduceMotion)
        let path = MovementPath.points(
            origin: origin,
            distance: distance,
            steps: steps,
            pattern: settings.pattern,
            restore: settings.restorePosition,
            generator: &generator
        )

        guard path.count >= 2 else {
            AppLog.movement.error("Jiggle path was empty for \(settings.pattern.rawValue, privacy: .public)")
            return
        }

        AppLog.movement.info(
            "Jiggle \(settings.pattern.rawValue, privacy: .public) \(distance, format: .fixed(precision: 1))px \(path.count) points \(settings.durationMilliseconds, format: .fixed(precision: 0))ms from (\(origin.x, format: .fixed(precision: 0)), \(origin.y, format: .fixed(precision: 0))) restore=\(settings.restorePosition) reduceMotion=\(reduceMotion)"
        )

        let total = max(settings.durationMilliseconds, 1)
        let stepDelay = total / Double(max(path.count - 1, 1))

        for point in path {
            if Task.isCancelled {
                AppLog.movement.info("Jiggle cancelled; restoring=\(settings.restorePosition)")
                if settings.restorePosition {
                    move(to: origin)
                }
                return
            }
            move(to: point)
            try? await Task.sleep(for: .milliseconds(stepDelay))
        }
    }

    /// `NSEvent.mouseLocation` is Cocoa (origin bottom-left). CGEvent uses Quartz (origin top-left).
    private static func quartzLocation(from cocoa: NSPoint) -> CGPoint {
        let maxY = NSScreen.screens.first?.frame.maxY ?? cocoa.y
        return CGPoint(x: cocoa.x, y: maxY - cocoa.y)
    }
}
