import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Vision

/// A fresh still-photo scan, NOT the possibly stale rectangle from the live preview.
/// Correcting perspective changes the image, so the untouched master is always kept.
nonisolated enum SurfacePhotoProcessor {
    /// The processor should only frame a reasonably large, confident object.
    /// A bad detection must NEVER silently crop the user's only photograph.
    static func bestSurface(in image: CGImage) -> DetectedSurface? {
        (try? RectangularSurfaceDetector.detect(in: image, orientation: .up))
            ?.filter { $0.isValid && $0.confidence >= 0.45
                    && $0.areaFraction >= 0.075
                    && $0.areaFraction <= 0.97 }
            .max { score($0) < score($1) }
    }

    static func rectifiedImage(from image: CGImage, surface: DetectedSurface) -> CGImage? {
        guard surface.isValid,
              surface.areaFraction >= 0.075,
              surface.areaFraction <= 0.97,
              image.width >= 100, image.height >= 100 else {
            return nil
        }

        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        func point(_ p: SurfacePoint) -> CGPoint {
            CGPoint(x: p.x * width, y: p.y * height)
        }
        let tl = point(surface.topLeft)
        let tr = point(surface.topRight)
        let br = point(surface.bottomRight)
        let bl = point(surface.bottomLeft)

        func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            hypot(a.x - b.x, a.y - b.y)
        }
        let horizontal = max(distance(tl, tr), distance(bl, br))
        let vertical = max(distance(tl, bl), distance(tr, br))
        guard horizontal >= 80, vertical >= 80 else { return nil }

        // Preserve the photographed plane and rectify its perspective, instead
        // of using a rectangular bounding box that leaves background visible.
        let correction = CIFilter.perspectiveCorrection()
        correction.inputImage = CIImage(cgImage: image)
        correction.topLeft = tl
        correction.topRight = tr
        correction.bottomRight = br
        correction.bottomLeft = bl

        guard let result = correction.outputImage,
              result.extent.isFinite,
              result.extent.width >= 80,
              result.extent.height >= 80,
              result.extent.width <= width * 2,
              result.extent.height <= height * 2 else {
            return nil
        }

        return CIContext().createCGImage(result, from: result.extent)
    }

    private static func score(_ item: DetectedSurface) -> Double {
        let c = item.corners
        let x = c.map(\.x).reduce(0, +) / 4
        let y = c.map(\.y).reduce(0, +) / 4
        let distance = hypot(x - 0.5, y - 0.5)
        return item.areaFraction * 0.65 + item.confidence * 0.18
            - distance * 0.22
    }
}
