import Foundation
import Testing
import UIKit
@testable import Fielens

struct OriginalPhotoTests {
    @Test func temporaryJPEGKeepsExactlyTheOriginalBytes() throws {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 32, height: 24),
            format: format
        )
        let testImage = renderer.image { context in
            UIColor.systemGreen.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 24))
        }

        let original = try #require(testImage.jpegData(compressionQuality: 0.95))
        let captured = try TemporaryPhotoStore.saveOriginalJPEG(original)
        defer { TemporaryPhotoStore.discard(captured) }

        #expect(captured.pixelWidth == 32)
        #expect(captured.pixelHeight == 24)
        #expect(captured.byteCount == original.count)
        #expect(try Data(contentsOf: captured.fileURL) == original)
    }

    @Test func invalidImageDataIsNotAccepted() {
        let invalid = Data("not a JPEG".utf8)
        #expect(throws: CameraCaptureError.self) {
            try TemporaryPhotoStore.saveOriginalJPEG(invalid)
        }
    }
}
