import Foundation

enum MovementPattern: String, Codable, CaseIterable, Identifiable, Sendable {
    case horizontal
    case vertical
    case diagonal
    case circle
    case figureEight
    case randomAngle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .horizontal: "Horizontal"
        case .vertical: "Vertical"
        case .diagonal: "Diagonal"
        case .circle: "Circle"
        case .figureEight: "Figure eight"
        case .randomAngle: "Random direction"
        }
    }

    var systemImage: String {
        switch self {
        case .horizontal: "arrow.left.and.right"
        case .vertical: "arrow.up.and.down"
        case .diagonal: "arrow.up.right.and.arrow.down.left"
        case .circle: "circle"
        case .figureEight: "infinity"
        case .randomAngle: "shuffle"
        }
    }

    var detail: String {
        switch self {
        case .horizontal: "Nudge left and right, then return."
        case .vertical: "Nudge up and down, then return."
        case .diagonal: "Travel on a short diagonal and back."
        case .circle: "Trace a small loop around the pointer."
        case .figureEight: "Trace a compact figure-eight."
        case .randomAngle: "Pick a new heading for every jiggle."
        }
    }
}

struct MovementSettings: Codable, Equatable, Sendable {
    /// Seconds between jiggles.
    var intervalSeconds: Double
    /// Extra random wait as a percent of the interval.
    var intervalJitterPercent: Double
    /// Peak travel distance in pixels.
    var distancePixels: Double
    /// Extra random distance as a percent of the distance.
    var distanceJitterPercent: Double
    /// How long one jiggle takes, in milliseconds.
    var durationMilliseconds: Double
    /// 0 is a two-point snap, 1 is a densely interpolated path.
    var smoothness: Double
    var pattern: MovementPattern
    var restorePosition: Bool
    var pauseWhileUsingPointer: Bool
    /// Seconds with no mouse or keyboard input after activity before the next jiggle.
    var idleGraceSeconds: Double

    static let `default` = MovementSettings(
        intervalSeconds: 5,
        intervalJitterPercent: 15,
        distancePixels: 8,
        distanceJitterPercent: 20,
        durationMilliseconds: 220,
        smoothness: 0.55,
        pattern: .horizontal,
        restorePosition: true,
        pauseWhileUsingPointer: true,
        idleGraceSeconds: 2
    )

    func stepCount(reduceMotion: Bool) -> Int {
        if reduceMotion { return 2 }
        return max(2, Int((4 + smoothness * 44).rounded()))
    }

    func nextInterval(using generator: inout some RandomNumberGenerator) -> Duration {
        let seconds = jittered(
            intervalSeconds,
            percent: intervalJitterPercent,
            using: &generator
        )
        return .seconds(max(0.2, seconds))
    }

    func nextDistance(using generator: inout some RandomNumberGenerator) -> Double {
        max(1, jittered(distancePixels, percent: distanceJitterPercent, using: &generator))
    }

    private func jittered(
        _ value: Double,
        percent: Double,
        using generator: inout some RandomNumberGenerator
    ) -> Double {
        guard percent > 0 else { return value }
        let span = value * (percent / 100)
        return value + Double.random(in: -span...span, using: &generator)
    }
}
