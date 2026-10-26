import Foundation
import Testing
@testable import Fielens

struct SurfaceGeometryTests {
    private func rect(
        minX: Double, minY: Double, maxX: Double, maxY: Double,
        confidence: Double = 0.95
    ) -> DetectedSurface {
        DetectedSurface(
            topLeft: SurfacePoint(x: minX, y: maxY),
            topRight: SurfacePoint(x: maxX, y: maxY),
            bottomRight: SurfacePoint(x: maxX, y: minY),
            bottomLeft: SurfacePoint(x: minX, y: minY),
            confidence: confidence
        )
    }

    @Test func rectangleHasNormalizedArea() {
        let a = rect(minX: 0.2, minY: 0.3, maxX: 0.8, maxY: 0.9)
        #expect(a.isValid)
        #expect(abs(a.areaFraction - 0.36) < 1e-10)
    }

    @Test func touchSelectsOnlyContainedRectangle() throws {
        let candidate = rect(minX: 0.1, minY: 0.2, maxX: 0.9, maxY: 0.8)
        #expect(SurfaceSelector.selected(at: SurfacePoint(x: 0.5, y: 0.5), in: [candidate])?.id == candidate.id)
        #expect(SurfaceSelector.selected(at: SurfacePoint(x: 0.95, y: 0.5), in: [candidate]) == nil)
    }

    @Test func touchInsideOverlappingRectanglesSelectsSmaller() {
        let big = rect(minX: 0.1, minY: 0.1, maxX: 0.9, maxY: 0.9)
        let small = rect(minX: 0.3, minY: 0.3, maxX: 0.7, maxY: 0.7)
        #expect(SurfaceSelector.selected(at: SurfacePoint(x: 0.5, y: 0.5), in: [big, small])?.id == small.id)
    }

    @Test func tapsAtEdgesCountAsInside() {
        let a = rect(minX: 0.2, minY: 0.2, maxX: 0.8, maxY: 0.8)
        #expect(a.contains(SurfacePoint(x: 0.2, y: 0.5)))
        #expect(a.contains(SurfacePoint(x: 0.8, y: 0.8)))
    }

    @Test func degenerateAndInvalidQuadrilateralsAreRejected() {
        let flat = rect(minX: 0.2, minY: 0.4, maxX: 0.8, maxY: 0.4)
        #expect(!flat.isValid)
        let outside = rect(minX: -0.1, minY: 0.2, maxX: 0.9, maxY: 0.8)
        #expect(!outside.isValid)
        let nan = rect(minX: .nan, minY: 0.2, maxX: 0.9, maxY: 0.8)
        #expect(!nan.isValid)
    }

    @Test func selfCrossingQuadIsRejected() {
        let bowTie = DetectedSurface(
            topLeft: SurfacePoint(x: 0.1, y: 0.9),
            topRight: SurfacePoint(x: 0.9, y: 0.1),
            bottomRight: SurfacePoint(x: 0.9, y: 0.9),
            bottomLeft: SurfacePoint(x: 0.1, y: 0.1),
            confidence: 0.9
        )
        #expect(!bowTie.isValid)
    }
    @Test func previewCoordinateConversionIsInvertible() {
        let corners = [
            SurfacePoint(x: 0, y: 0),
            SurfacePoint(x: 0.1, y: 0.85),
            SurfacePoint(x: 0.5, y: 0.5),
            SurfacePoint(x: 1, y: 1)
        ]
        for vision in corners {
            let capture = SurfaceCoordinateMapper.capturePoint(fromVision: vision)
            let roundTrip = SurfaceCoordinateMapper.visionPoint(fromCapture: capture)
            // 1 - (1 - 0.1) is not bit-for-bit equal to 0.1 in IEEE 754.
            #expect(abs(roundTrip.x - vision.x) < 1e-12)
            #expect(abs(roundTrip.y - vision.y) < 1e-12)
        }
        let converted = SurfaceCoordinateMapper.capturePoint(
            fromVision: SurfacePoint(x: 0.2, y: 0.9)
        )
        // Vision '.right' means 90° clockwise. The inverse transform
        // swaps the axes: (x, y) -> (1-y, 1-x) in RAW sensor space.
        #expect(abs(converted.x - 0.1) < 1e-12)
        #expect(abs(converted.y - 0.8) < 1e-12)
    }

    @Test func visionRightOrientationMapsEveryCornerBackToUnrotatedSensor() {
        // Four upright corners in Vision (bottom-left origin), whose
        // original buffer is landscape / unrotated with top-left origin.
        let cases: [(SurfacePoint, SurfacePoint)] = [
            (SurfacePoint(x: 0, y: 1), SurfacePoint(x: 0, y: 1)), // upright TL
            (SurfacePoint(x: 1, y: 1), SurfacePoint(x: 0, y: 0)), // upright TR
            (SurfacePoint(x: 1, y: 0), SurfacePoint(x: 1, y: 0)), // upright BR
            (SurfacePoint(x: 0, y: 0), SurfacePoint(x: 1, y: 1))  // upright BL
        ]
        for (vision, expectedCapture) in cases {
            let actualCapture = SurfaceCoordinateMapper.capturePoint(fromVision: vision)
            #expect(actualCapture == expectedCapture)
            let roundTrip = SurfaceCoordinateMapper.visionPoint(fromCapture: actualCapture)
            #expect(roundTrip == vision)
        }
    }

    @Test func visionRightOrientationHasNoMirrorErrorForOffCenterPoint() {
        let point = SurfacePoint(x: 0.25, y: 0.75)
        let capture = SurfaceCoordinateMapper.capturePoint(fromVision: point)
        #expect(abs(capture.x - 0.25) < 1e-12)
        #expect(abs(capture.y - 0.75) < 1e-12)

        let other = SurfacePoint(x: 0.1, y: 0.2)
        let mapped = SurfaceCoordinateMapper.capturePoint(fromVision: other)
        #expect(abs(mapped.x - 0.8) < 1e-12)
        #expect(abs(mapped.y - 0.9) < 1e-12)
    }

    @Test func tiltedConvexSurfaceCanBeSelected() {
        let shape = DetectedSurface(
            topLeft: SurfacePoint(x: 0.25, y: 0.85),
            topRight: SurfacePoint(x: 0.65, y: 0.79),
            bottomRight: SurfacePoint(x: 0.79, y: 0.24),
            bottomLeft: SurfacePoint(x: 0.19, y: 0.16),
            confidence: 0.9
        )
        #expect(shape.isValid)
        #expect(shape.contains(SurfacePoint(x: 0.5, y: 0.5)))
        #expect(!shape.contains(SurfacePoint(x: 0.9, y: 0.9)))
    }


    @Test func touchUsesTheSameVisibleScreenPolygon() throws {
        let outerID = UUID()
        let innerID = UUID()
        let outer = SurfaceScreenPolygon(
            id: outerID,
            corners: [
                SurfaceViewPoint(x: 0.1, y: 0.1),
                SurfaceViewPoint(x: 0.9, y: 0.1),
                SurfaceViewPoint(x: 0.9, y: 0.85),
                SurfaceViewPoint(x: 0.1, y: 0.85)
            ]
        )
        let inner = SurfaceScreenPolygon(
            id: innerID,
            corners: [
                SurfaceViewPoint(x: 0.4, y: 0.4),
                SurfaceViewPoint(x: 0.6, y: 0.4),
                SurfaceViewPoint(x: 0.6, y: 0.6),
                SurfaceViewPoint(x: 0.4, y: 0.6)
            ]
        )
        #expect(outer.contains(SurfaceViewPoint(x: 0.5, y: 0.5)))
        #expect(inner.contains(SurfaceViewPoint(x: 0.5, y: 0.5)))
        // Text inside a document must not steal selection of the whole page.
        #expect(SurfaceScreenSelector.selected(
            at: SurfaceViewPoint(x: 0.5, y: 0.5),
            from: [inner, outer]
        ) == outerID)
        #expect(SurfaceScreenSelector.selected(
            at: SurfaceViewPoint(x: 0.02, y: 0.5),
            from: [inner, outer]
        ) == nil)
    }

    @Test func selectsConvexTrapezoidAtRenderedCoordinates() throws {
        let id = UUID()
        let sheet = SurfaceScreenPolygon(
            id: id,
            corners: [
                SurfaceViewPoint(x: 0.25, y: 0.18),
                SurfaceViewPoint(x: 0.78, y: 0.16),
                SurfaceViewPoint(x: 0.7, y: 0.83),
                SurfaceViewPoint(x: 0.15, y: 0.79)
            ]
        )
        #expect(sheet.contains(SurfaceViewPoint(x: 0.5, y: 0.5)))
        #expect(!sheet.contains(SurfaceViewPoint(x: 0.9, y: 0.8)))
        #expect(SurfaceScreenSelector.selected(
            at: SurfaceViewPoint(x: 0.5, y: 0.5),
            from: [sheet]
        ) == id)
        #expect(sheet.area > 0.2)
    }

    @Test func rejectsCollapsedOrNotFiniteRenderedQuads() {
        let invalid = SurfaceScreenPolygon(
            id: UUID(),
            corners: [
                SurfaceViewPoint(x: 0.5, y: 0.5),
                SurfaceViewPoint(x: 0.5, y: 0.5),
                SurfaceViewPoint(x: 0.5, y: 0.5),
                SurfaceViewPoint(x: 0.5, y: 0.5)
            ]
        )
        #expect(!invalid.contains(SurfaceViewPoint(x: 0.5, y: 0.5)))
        let nan = SurfaceScreenPolygon(
            id: UUID(),
            corners: [
                SurfaceViewPoint(x: Double.nan, y: 0.2),
                SurfaceViewPoint(x: 0.8, y: 0.2),
                SurfaceViewPoint(x: 0.8, y: 0.8),
                SurfaceViewPoint(x: 0.2, y: 0.8)
            ]
        )
        #expect(!nan.contains(SurfaceViewPoint(x: 0.5, y: 0.5)))
    }


    @Test func oneCornerCanMoveWithoutBreakingConvexity() {
        let id = UUID()
        let initial = [
            SurfaceViewPoint(x: 0.1, y: 0.2),
            SurfaceViewPoint(x: 0.8, y: 0.45), // Misidentified top-right.
            SurfaceViewPoint(x: 0.8, y: 0.85),
            SurfaceViewPoint(x: 0.1, y: 0.85)
        ]
        #expect(SurfaceScreenPolygon(id: id, corners: initial).isConvex)

        var corrected = initial
        corrected[1] = SurfaceViewPoint(x: 0.8, y: 0.2)
        let adjusted = SurfaceScreenPolygon(id: id, corners: corrected)
        #expect(adjusted.isConvex)
        #expect(adjusted.contains(SurfaceViewPoint(x: 0.75, y: 0.25)))
        #expect(abs(adjusted.area - 0.455) < 1e-12)
    }

    @Test func draggingCornerAcrossOppositeEdgeIsRejected() {
        let id = UUID()
        let crossing = SurfaceScreenPolygon(
            id: id,
            corners: [
                SurfaceViewPoint(x: 0.2, y: 0.2),
                SurfaceViewPoint(x: 0.8, y: 0.2),
                SurfaceViewPoint(x: 0.1, y: 0.9), // dragged across left edge
                SurfaceViewPoint(x: 0.2, y: 0.8)
            ]
        )
        #expect(!crossing.isConvex)
        #expect(!crossing.contains(SurfaceViewPoint(x: 0.4, y: 0.4)))
    }

}
