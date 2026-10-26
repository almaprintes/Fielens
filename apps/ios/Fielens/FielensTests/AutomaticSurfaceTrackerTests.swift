import Foundation
import Testing
@testable import Fielens

struct AutomaticSurfaceTrackerTests {
    private func rect(
        x: Double, y: Double, size: Double,
        confidence: Double = 0.9
    ) -> DetectedSurface {
        DetectedSurface(
            topLeft: SurfacePoint(x: x, y: y + size),
            topRight: SurfacePoint(x: x + size, y: y + size),
            bottomRight: SurfacePoint(x: x + size, y: y),
            bottomLeft: SurfacePoint(x: x, y: y),
            confidence: confidence
        )
    }

    @Test func automaticallySelectsMainCenteredSurfaceOverSmallPrint() throws {
        let page = rect(x: 0.18, y: 0.16, size: 0.64)
        let smallBox = rect(x: 0.46, y: 0.46, size: 0.09)
        let result = AutomaticSurfaceTracker.update(
            previous: [],
            incoming: [smallBox, page],
            selectedID: nil
        )
        #expect(result.selectedID == page.id)
    }

    @Test func stableIDSurvivesSlightDeviceMovement() throws {
        let initial = rect(x: 0.20, y: 0.18, size: 0.60)
        let shifted = rect(x: 0.24, y: 0.20, size: 0.60)
        let result = AutomaticSurfaceTracker.update(
            previous: [initial],
            incoming: [shifted],
            selectedID: initial.id
        )
        #expect(result.selectedID == initial.id)
        let tracked = try #require(result.surfaces.first)
        #expect(tracked.id == initial.id)
        #expect(tracked.topLeft.x > initial.topLeft.x)
        #expect(tracked.topLeft.x < shifted.topLeft.x)
    }

    @Test func manualChoiceIsPreservedWhileSurfaceIsTrackable() throws {
        let big = rect(x: 0.1, y: 0.1, size: 0.8)
        let small = rect(x: 0.42, y: 0.42, size: 0.15)
        let nextBig = rect(x: 0.12, y: 0.1, size: 0.78)
        let nextSmall = rect(x: 0.44, y: 0.43, size: 0.15)
        let result = AutomaticSurfaceTracker.update(
            previous: [big, small],
            incoming: [nextBig, nextSmall],
            selectedID: small.id
        )
        #expect(result.selectedID == small.id)
    }

    @Test func rejectedObjectsDoNotKeepStaleSelection() {
        let page = rect(x: 0.1, y: 0.1, size: 0.7)
        let result = AutomaticSurfaceTracker.update(
            previous: [page], incoming: [], selectedID: page.id
        )
        #expect(result.surfaces.isEmpty)
        #expect(result.selectedID == nil)
    }

    @Test func ignoresVerySmallCentralTextBoxesWhenAlone() {
        let text = rect(x: 0.48, y: 0.48, size: 0.09)
        let result = AutomaticSurfaceTracker.update(
            previous: [], incoming: [text], selectedID: nil
        )
        #expect(result.selectedID == nil)
    }

    @Test func newDistantRectangleDoesNotInheritPreviousIdentity() throws {
        let a = rect(x: 0.04, y: 0.04, size: 0.24)
        let b = rect(x: 0.70, y: 0.70, size: 0.24)
        let result = AutomaticSurfaceTracker.update(
            previous: [a], incoming: [b], selectedID: a.id
        )
        #expect(result.surfaces.first?.id == b.id)
        #expect(result.selectedID == b.id)
    }
}
