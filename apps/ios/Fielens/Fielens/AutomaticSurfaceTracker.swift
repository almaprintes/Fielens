import Foundation

/// Stable IDs and modest smoothing for successively detected rectangles.
/// Detection still comes from Vision; this does not infer the plane's 3D normal.
nonisolated struct SurfaceTrackingUpdate: Sendable {
    let surfaces: [DetectedSurface]
    let selectedID: UUID?
}

nonisolated enum AutomaticSurfaceTracker {
    /// A relative threshold: large enough for hand tremor, small enough to avoid
    /// transferring a user selection to a completely different object.
    static let matchingCenterDistance = 0.22

    static func update(
        previous: [DetectedSurface],
        incoming: [DetectedSurface],
        selectedID: UUID?
    ) -> SurfaceTrackingUpdate {
        let candidates = incoming.filter(\.isValid)
        var previousAvailable = previous.filter(\.isValid)
        var tracked: [DetectedSurface] = []

        for candidate in candidates {
            let candidateCenter = center(of: candidate)
            let match = previousAvailable.enumerated().compactMap { index, old
                -> (index: Int, distance: Double)? in
                let centerDistance = distance(candidateCenter, center(of: old))
                let ratio = candidate.areaFraction / max(old.areaFraction, 0.00001)
                guard centerDistance < matchingCenterDistance,
                      ratio > 0.45, ratio < 2.2 else { return nil }
                return (index, centerDistance)
            }.min { $0.distance < $1.distance }

            if let match {
                let old = previousAvailable.remove(at: match.index)
                tracked.append(smoothed(current: candidate, previous: old))
            } else {
                tracked.append(candidate)
            }
        }

        if let selectedID, tracked.contains(where: { $0.id == selectedID }) {
            return SurfaceTrackingUpdate(surfaces: tracked, selectedID: selectedID)
        }

        // Select an adequately large rectangle near the camera's center.
        // Small inner text boxes are much less likely to win.
        let eligible = tracked.filter { $0.areaFraction >= 0.045 }
        let preferred = eligible.max { quality($0) < quality($1) }
        return SurfaceTrackingUpdate(surfaces: tracked, selectedID: preferred?.id)
    }

    private static func center(of item: DetectedSurface) -> SurfacePoint {
        let corners = item.corners
        return SurfacePoint(
            x: corners.map(\.x).reduce(0, +) / 4,
            y: corners.map(\.y).reduce(0, +) / 4
        )
    }

    private static func distance(_ a: SurfacePoint, _ b: SurfacePoint) -> Double {
        hypot(a.x - b.x, a.y - b.y)
    }

    private static func quality(_ item: DetectedSurface) -> Double {
        let c = center(of: item)
        let centrality = min(1.0, hypot(c.x - 0.5, c.y - 0.5) / 0.70)
        // Prefer a large, centered region with a trustworthy Vision score.
        return min(item.areaFraction, 0.80) * 0.70
            + item.confidence * 0.18
            - centrality * 0.23
    }

    private static func smoothed(
        current: DetectedSurface,
        previous: DetectedSurface
    ) -> DetectedSurface {
        // Filter micro-jitter without producing an extremely slow outline.
        let alpha = 0.68
        let corners = zip(previous.corners, current.corners).map { a, b in
            SurfacePoint(
                x: a.x + (b.x - a.x) * alpha,
                y: a.y + (b.y - a.y) * alpha
            )
        }
        guard corners.count == 4 else { return current }
        let smooth = DetectedSurface(
            id: previous.id,
            topLeft: corners[0],
            topRight: corners[1],
            bottomRight: corners[2],
            bottomLeft: corners[3],
            confidence: current.confidence
        )
        return smooth.isValid ? smooth : current
    }
}
