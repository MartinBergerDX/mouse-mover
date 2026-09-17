import AppKit

/// Kept so the app icon can switch back from pineapple in `GenerateIcons.swift`.
struct AppleIcon: FruitIcon {
    let name = "apple"

    func drawColor(in rect: NSRect) {
        let scale = rect.width / 1024
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale)
        }
        func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
            NSRect(
                x: rect.minX + x * scale,
                y: rect.minY + y * scale,
                width: w * scale,
                height: h * scale
            )
        }

        let rounded = NSBezierPath(roundedRect: r(64, 64, 896, 896), xRadius: 220 * scale, yRadius: 220 * scale)
        NSColor(calibratedRed: 0.18, green: 0.52, blue: 0.34, alpha: 1).setFill()
        rounded.fill()

        let leaf = NSBezierPath()
        leaf.move(to: p(530, 730))
        leaf.curve(to: p(720, 820), controlPoint1: p(560, 800), controlPoint2: p(650, 840))
        leaf.curve(to: p(530, 730), controlPoint1: p(700, 760), controlPoint2: p(600, 720))
        leaf.close()
        NSColor(calibratedRed: 0.45, green: 0.78, blue: 0.32, alpha: 1).setFill()
        leaf.fill()

        let stem = NSBezierPath()
        stem.move(to: p(508, 720))
        stem.curve(to: p(548, 860), controlPoint1: p(500, 780), controlPoint2: p(520, 840))
        stem.lineWidth = 36 * scale
        stem.lineCapStyle = .round
        NSColor(calibratedRed: 0.42, green: 0.26, blue: 0.14, alpha: 1).setStroke()
        stem.stroke()

        let body = NSBezierPath()
        body.move(to: p(512, 700))
        body.curve(to: p(220, 430), controlPoint1: p(300, 700), controlPoint2: p(200, 580))
        body.curve(to: p(512, 180), controlPoint1: p(230, 260), controlPoint2: p(360, 180))
        body.curve(to: p(804, 430), controlPoint1: p(664, 180), controlPoint2: p(794, 260))
        body.curve(to: p(512, 700), controlPoint1: p(824, 580), controlPoint2: p(724, 700))
        body.close()
        NSColor(calibratedRed: 0.86, green: 0.18, blue: 0.22, alpha: 1).setFill()
        body.fill()

        let shine = NSBezierPath(ovalIn: r(330, 470, 110, 160))
        NSColor.white.withAlphaComponent(0.28).setFill()
        shine.fill()
    }

    func drawTemplate(in rect: NSRect, filled: Bool) {
        let body = appleBody(in: rect)
        let stem = appleStem(in: rect)
        let leaf = appleLeaf(in: rect)
        NSColor.black.set()
        if filled {
            body.fill()
            leaf.fill()
            stem.lineWidth = max(1.4, rect.width * 0.08)
            stem.lineCapStyle = .round
            stem.stroke()
        } else {
            let line = max(1.15, rect.width * 0.07)
            body.lineWidth = line
            body.lineJoinStyle = .round
            body.stroke()
            leaf.lineWidth = line
            leaf.stroke()
            stem.lineWidth = line
            stem.lineCapStyle = .round
            stem.stroke()
        }
    }

    private func appleBody(in rect: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
        let x = rect.minX
        let y = rect.minY
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: x + w * 0.50, y: y + h * 0.74))
        path.curve(
            to: CGPoint(x: x + w * 0.10, y: y + h * 0.40),
            controlPoint1: CGPoint(x: x + w * 0.22, y: y + h * 0.74),
            controlPoint2: CGPoint(x: x + w * 0.06, y: y + h * 0.60)
        )
        path.curve(
            to: CGPoint(x: x + w * 0.50, y: y + h * 0.06),
            controlPoint1: CGPoint(x: x + w * 0.12, y: y + h * 0.16),
            controlPoint2: CGPoint(x: x + w * 0.30, y: y + h * 0.06)
        )
        path.curve(
            to: CGPoint(x: x + w * 0.90, y: y + h * 0.40),
            controlPoint1: CGPoint(x: x + w * 0.70, y: y + h * 0.06),
            controlPoint2: CGPoint(x: x + w * 0.88, y: y + h * 0.16)
        )
        path.curve(
            to: CGPoint(x: x + w * 0.50, y: y + h * 0.74),
            controlPoint1: CGPoint(x: x + w * 0.94, y: y + h * 0.60),
            controlPoint2: CGPoint(x: x + w * 0.78, y: y + h * 0.74)
        )
        path.close()
        return path
    }

    private func appleStem(in rect: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
        let x = rect.minX
        let y = rect.minY
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: x + w * 0.50, y: y + h * 0.72))
        path.curve(
            to: CGPoint(x: x + w * 0.58, y: y + h * 0.94),
            controlPoint1: CGPoint(x: x + w * 0.48, y: y + h * 0.82),
            controlPoint2: CGPoint(x: x + w * 0.52, y: y + h * 0.90)
        )
        return path
    }

    private func appleLeaf(in rect: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
        let x = rect.minX
        let y = rect.minY
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: x + w * 0.52, y: y + h * 0.80))
        path.curve(
            to: CGPoint(x: x + w * 0.86, y: y + h * 0.92),
            controlPoint1: CGPoint(x: x + w * 0.58, y: y + h * 0.90),
            controlPoint2: CGPoint(x: x + w * 0.74, y: y + h * 0.96)
        )
        path.curve(
            to: CGPoint(x: x + w * 0.52, y: y + h * 0.80),
            controlPoint1: CGPoint(x: x + w * 0.84, y: y + h * 0.84),
            controlPoint2: CGPoint(x: x + w * 0.66, y: y + h * 0.78)
        )
        path.close()
        return path
    }
}
