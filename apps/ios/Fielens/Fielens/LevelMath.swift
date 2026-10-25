import Foundation

/// Geometry of the PHONE relative to gravity, not geometry of the photographed surface.
/// Positive x = gravity toward the device's right edge; positive y = toward its top edge.
/// Only valid when the screen faces generally upward (rear camera points down).
nonisolated struct LevelReading: Equatable, Sendable {
    let xDegrees: Double
    let yDegrees: Double

    /// Experimental UI tolerance, NOT a camera calibration or a product quality guarantee.
    static let experimentalToleranceDegrees = 2.0

    var isWithinExperimentalTolerance: Bool {
        abs(xDegrees) <= Self.experimentalToleranceDegrees &&
        abs(yDegrees) <= Self.experimentalToleranceDegrees
    }
}

nonisolated enum LevelMath {
    static func reading(gravityX x: Double, gravityY y: Double, gravityZ z: Double) -> LevelReading? {
        guard x.isFinite, y.isFinite, z.isFinite else { return nil }
        let magnitude = sqrt(x * x + y * y + z * z)
        guard magnitude.isFinite, magnitude > 0.5, magnitude < 1.5 else { return nil }

        let gx = x / magnitude
        let gy = y / magnitude
        let gz = z / magnitude

        // z ~ -1: screen facing up / rear camera facing down.
        // z ~ +1: phone upside down; z ~ 0: vertical. Neither is a valid leveling pose.
        guard gz < -0.35 else { return nil }
        let factor = 180.0 / Double.pi
        return LevelReading(
            xDegrees: atan2(gx, -gz) * factor,
            yDegrees: atan2(gy, -gz) * factor
        )
    }
}
