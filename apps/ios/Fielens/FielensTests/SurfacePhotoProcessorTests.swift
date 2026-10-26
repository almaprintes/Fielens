import Foundation
import Testing
import UIKit
@testable import Fielens

struct SurfacePhotoProcessorTests {
    private func image(width: Int = 1200, height: Int = 900) throws -> CGImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let result = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        ).image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            UIColor.white.setFill()
            context.fill(CGRect(x: 220, y: 180, width: 760, height: 540))
        }
        return try #require(result.cgImage)
    }

    private func rectangle() -> DetectedSurface {
        DetectedSurface(
            topLeft: SurfacePoint(x: 0.2, y: 0.8),
            topRight: SurfacePoint(x: 0.8, y: 0.8),
            bottomRight: SurfacePoint(x: 0.8, y: 0.2),
            bottomLeft: SurfacePoint(x: 0.2, y: 0.2),
            confidence: 0.95
        )
    }

    @Test func perspectiveRectificationProducesObjectSizedImage() throws {
        let original = try image()
        let correction = try #require(
            SurfacePhotoProcessor.rectifiedImage(
                from: original,
                surface: rectangle()
            )
        )
        #expect(correction.width < original.width)
        #expect(correction.height < original.height)
        #expect(correction.width >= 680)
        #expect(correction.height >= 500)
    }

    @Test func perspectiveResultHonorsMaximumLongEdge() throws {
        let original = try image()
        let rectified = try #require(
            SurfacePhotoProcessor.rectifiedImage(
                from: original,
                surface: rectangle(),
                maximumLongEdge: 500
            )
        )
        #expect(max(rectified.width, rectified.height) <= 500)
        #expect(rectified.width > 200)
        #expect(rectified.height > 200)
    }

    @Test func degenerateRegionCannotCropThePhoto() throws {
        let original = try image()
        let impossible = DetectedSurface(
            topLeft: SurfacePoint(x: 0.5, y: 0.5),
            topRight: SurfacePoint(x: 0.5, y: 0.5),
            bottomRight: SurfacePoint(x: 0.5, y: 0.5),
            bottomLeft: SurfacePoint(x: 0.5, y: 0.5),
            confidence: 1
        )
        #expect(SurfacePhotoProcessor.rectifiedImage(
            from: original,
            surface: impossible
        ) == nil)
    }

    @Test func originalFileIsNeverCroppedEvenWhenFramingIsRequested() throws {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let picture = UIGraphicsImageRenderer(
            size: CGSize(width: 96, height: 72),
            format: format
        ).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 96, height: 72))
        }
        let jpeg = try #require(picture.jpegData(compressionQuality: 0.9))
        let photo = try TemporaryPhotoStore.saveOriginalJPEG(jpeg)
        defer { TemporaryPhotoStore.discard(photo) }

        let exported = try PhotoExportService.prepareForReview(
            photo: photo, resolution: .original, frameObject: true
        )
        #expect(exported.fileURL == photo.fileURL)
        #expect(!exported.didFrameObject)
        #expect(try Data(contentsOf: exported.fileURL) == jpeg)
    }
}
