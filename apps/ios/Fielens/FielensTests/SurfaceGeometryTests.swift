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
        #expect(abs(converted.x - 0.2) < 1e-12)
        #expect(abs(converted.y - 0.1) < 1e-12)
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

}
