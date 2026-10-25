import Foundation
import Testing
@testable import Fielens

struct LevelMathTests {
    @Test func screenUpAndFlatIsLevel() throws {
        let sample = try #require(LevelMath.reading(gravityX: 0, gravityY: 0, gravityZ: -1))
        #expect(abs(sample.xDegrees) < 0.001)
        #expect(abs(sample.yDegrees) < 0.001)
        #expect(sample.isWithinExperimentalTolerance)
    }

    @Test func positivePhysicalXMeansPositiveAngleX() throws {
        let radians = 8.0 * Double.pi / 180.0
        let sample = try #require(LevelMath.reading(
            gravityX: sin(radians), gravityY: 0, gravityZ: -cos(radians)
        ))
        #expect(abs(sample.xDegrees - 8.0) < 0.01)
        #expect(abs(sample.yDegrees) < 0.01)
        #expect(!sample.isWithinExperimentalTolerance)
    }

    @Test func negativePhysicalYMeansNegativeAngleY() throws {
        let radians = 4.0 * Double.pi / 180.0
        let sample = try #require(LevelMath.reading(
            gravityX: 0, gravityY: -sin(radians), gravityZ: -cos(radians)
        ))
        #expect(abs(sample.yDegrees + 4.0) < 0.01)
    }

    @Test func experimentalTwoDegreeToleranceHasBoundary() throws {
        let almostFlat = LevelReading(xDegrees: 2.0, yDegrees: -2.0)
        #expect(almostFlat.isWithinExperimentalTolerance)
        let outside = LevelReading(xDegrees: 2.1, yDegrees: 0)
        #expect(!outside.isWithinExperimentalTolerance)
    }

    @Test func upsideDownOrUprightIsNeverMisreportedLevel() {
        #expect(LevelMath.reading(gravityX: 0, gravityY: 0, gravityZ: 1) == nil)
        #expect(LevelMath.reading(gravityX: 0, gravityY: 1, gravityZ: 0) == nil)
        #expect(LevelMath.reading(gravityX: 0, gravityY: 0, gravityZ: 0) == nil)
    }

    @Test func invalidSamplesAreRejected() {
        #expect(LevelMath.reading(gravityX: .nan, gravityY: 0, gravityZ: -1) == nil)
        #expect(LevelMath.reading(gravityX: .infinity, gravityY: 0, gravityZ: -1) == nil)
    }
}
