import Foundation
import ImageIO
import Testing
import UIKit
@testable import Fielens

struct PhotoExportTests {
    @Test func presetsHavePredictableBounds() {
        #expect(ExportResolution.compact.maximumLongEdge == 1600)
        #expect(ExportResolution.share.maximumLongEdge == 2400)
        #expect(ExportResolution.detailed.maximumLongEdge == 4000)
        #expect(ExportResolution.original.maximumLongEdge == nil)
    }

    @Test func originalExportIsIdenticalAndReducedExportKeepsSourceUnchanged() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 2400, height: 1600)).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 2400, height: 1600))
            UIColor.black.setFill()
            ctx.fill(CGRect(x: 40, y: 40, width: 600, height: 200))
        }
        let data = try #require(image.jpegData(compressionQuality: 0.93))
        let original = try TemporaryPhotoStore.saveOriginalJPEG(data)
        defer { TemporaryPhotoStore.discard(original) }

        let originalURL = try PhotoExportService.prepare(photo: original, resolution: .original)
        #expect(originalURL == original.fileURL)
        #expect(try Data(contentsOf: originalURL) == data)

        let compactURL = try PhotoExportService.prepare(photo: original, resolution: .compact)
        defer { PhotoExportService.discardTemporaryCopy(compactURL, original: original) }
        #expect(compactURL != original.fileURL)

        let resizedSource = try #require(CGImageSourceCreateWithURL(compactURL as CFURL, nil))
        let props = try #require(CGImageSourceCopyPropertiesAtIndex(resizedSource, 0, nil) as NSDictionary?)
        let width = try #require((props[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue)
        let height = try #require((props[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue)
        #expect(max(width, height) <= 1600)
        #expect(max(width, height) >= 1500)
        #expect(try Data(contentsOf: original.fileURL) == data)

        PhotoExportService.discardTemporaryCopy(compactURL, original: original)
        #expect(!FileManager.default.fileExists(atPath: compactURL.path))
        #expect(FileManager.default.fileExists(atPath: original.fileURL.path))
    }

    @Test func reducedCopyDoesNotForwardGPSMetadata() throws {
        let raster = UIGraphicsImageRenderer(size: CGSize(width: 240, height: 160)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 240, height: 160))
        }
        let cgImage = try #require(raster.cgImage)
        let raw = try #require(CFDataCreateMutable(nil, 0))
        let destination = try #require(CGImageDestinationCreateWithData(
            raw,
            "public.jpeg" as CFString,
            1,
            nil
        ))
        CGImageDestinationAddImage(destination, cgImage, [
            kCGImageDestinationLossyCompressionQuality: 0.9,
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 12.345,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 43.210,
                kCGImagePropertyGPSLongitudeRef: "W"
            ]
        ] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))

        let original = try TemporaryPhotoStore.saveOriginalJPEG(raw as Data)
        defer { TemporaryPhotoStore.discard(original) }
        let exportURL = try PhotoExportService.prepare(photo: original, resolution: .compact)
        defer { PhotoExportService.discardTemporaryCopy(exportURL, original: original) }

        let copySource = try #require(CGImageSourceCreateWithURL(exportURL as CFURL, nil))
        let copyProps = try #require(CGImageSourceCopyPropertiesAtIndex(copySource, 0, nil) as NSDictionary?)
        #expect(copyProps[kCGImagePropertyGPSDictionary] == nil)
    }

    @Test func aSmallPhotoIsNeverUpscaled() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 48)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 48))
        }
        let data = try #require(image.jpegData(compressionQuality: 0.9))
        let original = try TemporaryPhotoStore.saveOriginalJPEG(data)
        defer { TemporaryPhotoStore.discard(original) }

        let url = try PhotoExportService.prepare(photo: original, resolution: .share)
        defer { PhotoExportService.discardTemporaryCopy(url, original: original) }
        let source = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
        let imageOut = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(max(imageOut.width, imageOut.height) <= 64)
    }
}
