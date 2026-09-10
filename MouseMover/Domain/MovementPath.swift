import CoreGraphics
import Foundation

enum MovementPath {
    static func points(
        origin: CGPoint,
        distance: CGFloat,
        steps: Int,
        pattern: MovementPattern,
        restore: Bool,
        generator: inout some RandomNumberGenerator
    ) -> [CGPoint] {
        let count = max(2, steps)
        let angle = heading(for: pattern, generator: &generator)
        var path = (0..<count).map { index in
            let t = Double(index) / Double(count - 1)
            return point(
                origin: origin,
                distance: distance,
                t: t,
                pattern: pattern,
                angle: angle
            )
        }

        if restore, path.last != origin {
            path.append(origin)
        }
        return path
    }

    private static func heading(
        for pattern: MovementPattern,
        generator: inout some RandomNumberGenerator
    ) -> CGFloat {
        switch pattern {
        case .horizontal: 0
        case .vertical: .pi / 2
        case .diagonal: .pi / 4
        case .circle, .figureEight: 0
        case .randomAngle: CGFloat.random(in: 0..<(2 * .pi), using: &generator)
        }
    }

    private static func point(
        origin: CGPoint,
        distance: CGFloat,
        t: Double,
        pattern: MovementPattern,
        angle: CGFloat
    ) -> CGPoint {
        switch pattern {
        case .horizontal, .vertical, .diagonal, .randomAngle:
            let travel = CGFloat(sin(t * .pi)) * distance
            return CGPoint(
                x: origin.x + cos(angle) * travel,
                y: origin.y + sin(angle) * travel
            )
        case .circle:
            let theta = CGFloat(t) * 2 * .pi
            let radius = distance / 2
            return CGPoint(
                x: origin.x + sin(theta) * radius,
                y: origin.y + (1 - cos(theta)) * radius
            )
        case .figureEight:
            let theta = CGFloat(t) * 2 * .pi
            let radius = distance / 2
            return CGPoint(
                x: origin.x + sin(theta) * radius,
                y: origin.y + sin(2 * theta) * radius / 2
            )
        }
    }
}
