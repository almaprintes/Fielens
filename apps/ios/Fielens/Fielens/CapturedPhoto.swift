import Foundation
import ImageIO

/// Metadata of the unmodified JPEG returned by AVCapturePhoto.
/// The actual image bytes live in an app-private temporary file, never in the repo.
nonisolated struct CapturedPhoto: Identifiable, Sendable {
    let id: UUID
    let fileURL: URL
    let pixelWidth: Int
    let pixelHeight: Int
    let byteCount: Int

    var megapixels: Double {
        Double(pixelWidth) * Double(pixelHeight) / 1_000_000
    }
}

/// Only experiment artifacts belonging to Fielens are cleaned up.
/// A file is not a permanent photo-library save; the user can export via the Share sheet.
nonisolated enum TemporaryPhotoStore {
    private static var captureFolder: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("Fielens-Capture-Preview", isDirectory: true)
    }

    static func saveOriginalJPEG(_ data: Data) throws -> CapturedPhoto {
        guard data.count >= 3, data[0] == 0xFF, data[1] == 0xD8, data[2] == 0xFF else {
            throw CameraCaptureError.failed("El archivo generado no tiene formato JPEG.")
        }

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let rawProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = (rawProperties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
              let height = (rawProperties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
              width > 0, height > 0 else {
            throw CameraCaptureError.failed("No se puede determinar la resolución de la fotografía.")
        }

        try FileManager.default.createDirectory(
            at: captureFolder,
            withIntermediateDirectories: true
        )
        let id = UUID()
        let fileURL = captureFolder.appendingPathComponent(id.uuidString + ".jpg")
        // No conversion, crop, pixel editing or metadata rewrite.
        try data.write(to: fileURL, options: .atomic)
        return CapturedPhoto(
            id: id,
            fileURL: fileURL,
            pixelWidth: width,
            pixelHeight: height,
            byteCount: data.count
        )
    }

    static func discard(_ photo: CapturedPhoto) {
        // Do not allow arbitrary paths to be passed to a file deletion helper.
        guard photo.fileURL.deletingLastPathComponent().standardizedFileURL
                == captureFolder.standardizedFileURL else { return }
        try? FileManager.default.removeItem(at: photo.fileURL)
    }

    static func clearPreviousLaunch() {
        // The OS may not immediately delete files in temporaryDirectory.
        // We remove stale previews only when a new app session begins.
        try? FileManager.default.removeItem(at: captureFolder)
    }
}

nonisolated enum CameraCaptureError: Error, LocalizedError, Sendable {
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .failed(let message): message
        }
    }
}
