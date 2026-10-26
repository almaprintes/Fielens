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
}
