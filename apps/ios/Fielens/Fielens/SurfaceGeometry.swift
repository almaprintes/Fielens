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


/// Convert RECTANGLES OBSERVED WITH Vision orientation '.right' back into
/// AVFoundation capture-device coordinates (unrotated image, TOP-LEFT origin).
///
/// This is NOT just a Y flip. The source buffer is landscape-native and Vision
/// rotates it clockwise into portrait for analysis. In normalized coordinates:
///
/// upright image top-left (Vision x=0, y=1) -> raw sensor bottom-left (0, 1)
/// upright image top-right (Vision x=1, y=1) -> raw sensor top-left (0, 0)
/// upright image bottom-right (Vision x=1, y=0) -> raw sensor top-right (1, 0)
///
/// After this inverse 90° transform, AVCaptureVideoPreviewLayer applies its
/// OWN rotation and aspect-fill crop to the layer. Only valid while the scanner
/// passes '.right' to VNImageRequestHandler and the video data buffer is raw
/// landscape. Device rotations and rotated video buffers require a new mapping.
nonisolated enum SurfaceCoordinateMapper {
    static func capturePoint(fromVision point: SurfacePoint) -> SurfacePoint {
        SurfacePoint(x: 1 - point.y, y: 1 - point.x)
    }

    static func visionPoint(fromCapture point: SurfacePoint) -> SurfacePoint {
        SurfacePoint(x: 1 - point.y, y: 1 - point.x)
    }
}


// MARK: - Touch selection in the ACTUAL rendered preview coordinates

/// Normalized UIKit preview coordinates. Origin is TOP-LEFT, unlike Vision.
/// Hit testing MUST be performed here using the same projected corners we draw.
nonisolated struct SurfaceViewPoint: Equatable, Sendable {
    let x: Double
    let y: Double

    var isFinite: Bool { x.isFinite && y.isFinite }
}

nonisolated struct SurfaceScreenPolygon: Sendable {
    let id: UUID
    /// The four points used for the rendered overlay, in preview coordinates.
    let corners: [SurfaceViewPoint]

    var area: Double {
        guard corners.count == 4, corners.allSatisfy(\.isFinite) else { return 0 }
        let twiceArea = corners.indices.reduce(0.0) { sum, i in
            let a = corners[i]
            let b = corners[(i + 1) % corners.count]
            return sum + a.x * b.y - b.x * a.y
        }
        return abs(twiceArea) / 2
    }

    func contains(_ point: SurfaceViewPoint) -> Bool {
        guard point.isFinite, corners.count == 4, area > 0.000001 else {
            return false
        }
        // Convex polygon, coordinates correspond to the actual drawn screen path.
        var sign = 0
        for index in corners.indices {
            let a = corners[index]
            let b = corners[(index + 1) % corners.count]
            let cross = (b.x - a.x) * (point.y - a.y) -
                (b.y - a.y) * (point.x - a.x)
            if abs(cross) <= 1e-9 { continue }
            let nextSign = cross > 0 ? 1 : -1
            if sign != 0 && sign != nextSign { return false }
            sign = nextSign
        }
        return true
    }
}

/// One visual tap picks the OUTERMOST containing candidate by default, avoiding
/// accidental selection of tiny printed boxes/text inside a sheet of paper.
/// The UI also offers an explicit "Other contour" action for nested surfaces.
nonisolated enum SurfaceScreenSelector {
    static func selected(
        at tap: SurfaceViewPoint,
        from polygons: [SurfaceScreenPolygon]
    ) -> UUID? {
        polygons
            .filter { $0.contains(tap) }
            .max { $0.area < $1.area }?
            .id
    }
}

nonisolated struct SurfacePendingTap: Equatable, Sendable {
    let id: UUID
    let point: SurfaceViewPoint
}
