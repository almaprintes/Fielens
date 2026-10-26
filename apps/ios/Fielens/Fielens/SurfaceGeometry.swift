import Foundation

/// Normalized image coordinates: (0, 0) is the BOTTOM-LEFT, matching Vision.
/// The UI must transform touches through the actual preview crop/orientation first.
nonisolated struct SurfacePoint: Equatable, Sendable {
    let x: Double
    let y: Double

    var isNormalized: Bool {
        x.isFinite && y.isFinite && (0...1).contains(x) && (0...1).contains(y)
    }
}

/// An observed quadrilateral, not proof of a flat or rectangular physical object.
/// Corners follow the order: TL -> TR -> BR -> BL.
nonisolated struct DetectedSurface: Identifiable, Sendable {
    let id: UUID
    let topLeft: SurfacePoint
    let topRight: SurfacePoint
    let bottomRight: SurfacePoint
    let bottomLeft: SurfacePoint
    let confidence: Double

    init(
        id: UUID = UUID(),
        topLeft: SurfacePoint,
        topRight: SurfacePoint,
        bottomRight: SurfacePoint,
        bottomLeft: SurfacePoint,
        confidence: Double
    ) {
        self.id = id
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        self.confidence = confidence
    }

    var corners: [SurfacePoint] {
        [topLeft, topRight, bottomRight, bottomLeft]
    }

    var areaFraction: Double {
        let pts = corners
        let twiceArea = (0..<4).reduce(0.0) { total, i in
            let a = pts[i]
            let b = pts[(i + 1) % 4]
            return total + a.x * b.y - b.x * a.y
        }
        return abs(twiceArea) * 0.5
    }

    var isValid: Bool {
        guard corners.allSatisfy(\.isNormalized),
              confidence.isFinite && (0...1).contains(confidence),
              areaFraction > 0.0001 else {
            return false
        }

        // A self-intersecting or concave quadrilateral must never be selectable.
        let pts = corners
        var orientation = 0
        for i in 0..<4 {
            let a = pts[i]
            let b = pts[(i + 1) % 4]
            let c = pts[(i + 2) % 4]
            let cross = (b.x - a.x) * (c.y - b.y)
                - (b.y - a.y) * (c.x - b.x)
            if abs(cross) < 1e-8 { return false }
            let nextOrientation = cross > 0 ? 1 : -1
            if orientation != 0 && orientation != nextOrientation { return false }
            orientation = nextOrientation
        }
        return true
    }

    func contains(_ point: SurfacePoint) -> Bool {
        guard isValid, point.isNormalized else { return false }
        let pts = corners
        var direction = 0
        for i in 0..<4 {
            let a = pts[i]
            let b = pts[(i + 1) % 4]
            let cross = (b.x - a.x) * (point.y - a.y)
                - (b.y - a.y) * (point.x - a.x)
            if abs(cross) <= 1e-9 { continue }
            let nextDirection = cross > 0 ? 1 : -1
            if direction != 0 && nextDirection != direction { return false }
            direction = nextDirection
        }
        return true
    }
}

/// When a tap intersects nested rectangles, prefer the smallest valid one.
/// User confirmation/editing will be required before locking a contour.
nonisolated enum SurfaceSelector {
    static func selected(at point: SurfacePoint, in candidates: [DetectedSurface]) -> DetectedSurface? {
        candidates
            .filter { $0.contains(point) }
            .min {
                if abs($0.areaFraction - $1.areaFraction) > 0.000001 {
                    return $0.areaFraction < $1.areaFraction
                }
                return $0.confidence > $1.confidence
            }
    }
}
