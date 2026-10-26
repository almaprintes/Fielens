import CoreGraphics
import Foundation
import ImageIO
import Vision

/// Proof-of-concept detector. Call from a background queue with a reduced-size frame.
/// It returns candidates only: no "perpendicular" or "correct" verdict is produced.
nonisolated enum RectangularSurfaceDetector {
    static func detect(
        in image: CGImage,
        orientation: CGImagePropertyOrientation = .up
    ) throws -> [DetectedSurface] {
        let request = makeRequest()
        let handler = VNImageRequestHandler(
            cgImage: image,
            orientation: orientation,
            options: [:]
        )
        try handler.perform([request])

        return surfaces(from: request)
    }

    static func detect(
        in pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation = .right
    ) throws -> [DetectedSurface] {
        let request = makeRequest()
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        )
        try handler.perform([request])
        return surfaces(from: request)
    }

    private static func makeRequest() -> VNDetectRectanglesRequest {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 12
        request.minimumAspectRatio = 0.15
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.08
        request.minimumConfidence = 0.35
        request.quadratureTolerance = 35

        return request
    }

    private static func surfaces(from request: VNDetectRectanglesRequest) -> [DetectedSurface] {
        (request.results ?? []).compactMap { observation -> DetectedSurface? in
            let surface = DetectedSurface(
                topLeft: SurfacePoint(
                    x: Double(observation.topLeft.x),
                    y: Double(observation.topLeft.y)
                ),
                topRight: SurfacePoint(
                    x: Double(observation.topRight.x),
                    y: Double(observation.topRight.y)
                ),
                bottomRight: SurfacePoint(
                    x: Double(observation.bottomRight.x),
                    y: Double(observation.bottomRight.y)
                ),
                bottomLeft: SurfacePoint(
                    x: Double(observation.bottomLeft.x),
                    y: Double(observation.bottomLeft.y)
                ),
                confidence: Double(observation.confidence)
            )
            return surface.isValid ? surface : nil
        }
    }
}
