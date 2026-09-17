import AppKit

struct PineappleIcon: FruitIcon {
    let name = "pineapple"

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
        NSColor(calibratedRed: 0.14, green: 0.47, blue: 0.38, alpha: 1).setFill()
        rounded.fill()

        let bodyRect = r(318, 198, 388, 512)
        let body = NSBezierPath(roundedRect: bodyRect, xRadius: 180 * scale, yRadius: 180 * scale)
        NSColor(calibratedRed: 0.95, green: 0.74, blue: 0.18, alpha: 1).setFill()
        body.fill()

        NSGraphicsContext.current?.saveGraphicsState()
        body.addClip()
        let diamonds = NSBezierPath()
        diamonds.lineWidth = 18 * scale
        diamonds.lineCapStyle = .round
        diamonds.lineJoinStyle = .round
        let origin = bodyRect.origin
        for i in -4...8 {
            let x = origin.x + CGFloat(i) * 70 * scale
            diamonds.move(to: CGPoint(x: x, y: origin.y))
            diamonds.line(to: CGPoint(x: x + 520 * scale, y: origin.y + 520 * scale))
            diamonds.move(to: CGPoint(x: x + 520 * scale, y: origin.y))
            diamonds.line(to: CGPoint(x: x, y: origin.y + 520 * scale))
        }
        NSColor(calibratedRed: 0.82, green: 0.48, blue: 0.10, alpha: 0.85).setStroke()
        diamonds.stroke()
        NSGraphicsContext.current?.restoreGraphicsState()

        let shine = NSBezierPath(ovalIn: r(360, 430, 90, 150))
        NSColor.white.withAlphaComponent(0.22).setFill()
        shine.fill()

        let leafFills: [(NSColor, CGFloat, CGFloat, CGFloat)] = [
            (NSColor(calibratedRed: 0.22, green: 0.55, blue: 0.24, alpha: 1), -62, 0.78, 1.05),
            (NSColor(calibratedRed: 0.30, green: 0.66, blue: 0.28, alpha: 1), -38, 0.92, 1.18),
            (NSColor(calibratedRed: 0.36, green: 0.74, blue: 0.32, alpha: 1), -16, 1.00, 1.28),
            (NSColor(calibratedRed: 0.28, green: 0.62, blue: 0.26, alpha: 1), 16, 1.00, 1.28),
            (NSColor(calibratedRed: 0.32, green: 0.68, blue: 0.28, alpha: 1), 38, 0.92, 1.18),
            (NSColor(calibratedRed: 0.22, green: 0.55, blue: 0.24, alpha: 1), 62, 0.78, 1.05),
        ]
        for (color, angle, widthScale, heightScale) in leafFills {
            color.setFill()
            crownLeaf(
                base: p(512, 668),
                angle: angle,
                width: 92 * scale * widthScale,
                height: 210 * scale * heightScale
            ).fill()
        }
    }

    func drawTemplate(in rect: NSRect, filled: Bool) {
        NSColor.black.set()
        let body = pineappleBody(in: rect)
        let leaves = pineappleLeaves(in: rect)
        let line = max(1.15, rect.width * 0.07)
        if filled {
            leaves.forEach { $0.fill() }
            body.fill()
        } else {
            body.lineWidth = line
            body.lineJoinStyle = .round
            body.stroke()
            for leaf in leaves {
                leaf.lineWidth = line
                leaf.lineJoinStyle = .round
                leaf.stroke()
            }
        }
    }

    private func pineappleBody(in rect: NSRect) -> NSBezierPath {
        let bodyRect = NSRect(
            x: rect.minX + rect.width * 0.28,
            y: rect.minY + rect.height * 0.06,
            width: rect.width * 0.44,
            height: rect.height * 0.58
        )
        return NSBezierPath(roundedRect: bodyRect, xRadius: bodyRect.width * 0.48, yRadius: bodyRect.width * 0.48)
    }

    private func pineappleLeaves(in rect: NSRect) -> [NSBezierPath] {
        let base = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.58)
        let specs: [(CGFloat, CGFloat, CGFloat)] = [
            (-42, 0.72, 0.90),
            (-22, 0.86, 1.05),
            (0, 1.00, 1.18),
            (22, 0.86, 1.05),
            (42, 0.72, 0.90),
        ]
        return specs.map { angle, widthScale, heightScale in
            crownLeaf(
                base: base,
                angle: angle,
                width: rect.width * 0.16 * widthScale,
                height: rect.height * 0.40 * heightScale
            )
        }
    }

    private func crownLeaf(base: CGPoint, angle: CGFloat, width: CGFloat, height: CGFloat) -> NSBezierPath {
        let leaf = NSBezierPath()
        leaf.move(to: CGPoint(x: -width / 2, y: 0))
        leaf.curve(
            to: CGPoint(x: 0, y: height),
            controlPoint1: CGPoint(x: -width * 0.15, y: height * 0.35),
            controlPoint2: CGPoint(x: -width * 0.08, y: height * 0.78)
        )
        leaf.curve(
            to: CGPoint(x: width / 2, y: 0),
            controlPoint1: CGPoint(x: width * 0.08, y: height * 0.78),
            controlPoint2: CGPoint(x: width * 0.15, y: height * 0.35)
        )
        leaf.close()
        var transform = AffineTransform.identity
        transform.translate(x: base.x, y: base.y)
        transform.rotate(byDegrees: angle)
        leaf.transform(using: transform)
        return leaf
    }
}
