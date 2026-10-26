import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Desired resolution of the SHAREABLE COPY, not the sensor capture.
/// The full-resolution original remains available until the user chooses Repetir
/// or the temporary session is cleaned. No image is transmitted by Fielens.
nonisolated enum ExportResolution: String, CaseIterable, Identifiable, Sendable {
    case compact
    case share
    case detailed
    case original

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: "Ligera · 1600 px"
        case .share: "Compartir · 2400 px"
        case .detailed: "Detalle · 4000 px"
        case .original: "Original · máxima"
        }
    }

    var recommendation: String {
        switch self {
        case .compact: "Imagen ligera; revisar textos pequeños"
        case .share: "Recomendada para documentos por mensajería"
        case .detailed: "Para textos muy pequeños o impresiones"
        case .original: "Sin reducir ni recodificar"
        }
    }

    var maximumLongEdge: Int? {
        switch self {
        case .compact: 1600
        case .share: 2400
        case .detailed: 4000
        case .original: nil
        }
    }

    var jpegQuality: Double {
        switch self {
        case .compact: 0.82
        case .share: 0.88
        case .detailed: 0.92
        case .original: 1.0 // never used: returns original file unchanged
        }
    }

    /// Expected maximum long edge; never upscale small originals.
    func expectedLongEdge(for photo: CapturedPhoto) -> Int {
        min(max(photo.pixelWidth, photo.pixelHeight), maximumLongEdge ?? Int.max)
    }
}

nonisolated enum PhotoExportError: Error, LocalizedError, Sendable {
    case invalidSource
    case cannotCreateImage
    case cannotCreateDestination
    case cannotFinishFile

    var errorDescription: String? {
        switch self {
        case .invalidSource: "No se puede leer la fotografía original."
        case .cannotCreateImage: "No se puede preparar la copia de menor resolución."
        case .cannotCreateDestination: "No se puede preparar el archivo de envío."
        case .cannotFinishFile: "No se pudo completar el JPEG para compartir."
        }
    }
}

/// Creates new JPEG bytes using image downsampling, no hidden crops or filters.
/// A reduced shareable copy deliberately does not forward EXIF metadata.
/// Work must execute outside the main actor due to potentially large originals.
nonisolated enum PhotoExportService {
    static func prepare(photo: CapturedPhoto, resolution: ExportResolution) throws -> URL {
        // Exact original, including its metadata, remains available when requested.
        guard let maximum = resolution.maximumLongEdge else {
            guard FileManager.default.fileExists(atPath: photo.fileURL.path) else {
                throw PhotoExportError.invalidSource
            }
            return photo.fileURL
        }

        guard let source = CGImageSourceCreateWithURL(photo.fileURL as CFURL, nil),
              CGImageSourceGetCount(source) > 0 else {
            throw PhotoExportError.invalidSource
        }

        // ImageIO produces a downsampled, orientation-corrected raster without
        // first decoding the full 48 MP image into a giant UIImage.
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: resolution.expectedLongEdge(for: photo),
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw PhotoExportError.cannotCreateImage
        }

        // The generated file is in the same app-private temporary folder as the
        // source. It will be removed after the system share sheet is dismissed.
        let destinationURL = photo.fileURL.deletingLastPathComponent()
            .appendingPathComponent("fielens-share-\(UUID().uuidString).jpg")
        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw PhotoExportError.cannotCreateDestination
        }

        let jpegOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: resolution.jpegQuality
        ]
        CGImageDestinationAddImage(destination, thumbnail, jpegOptions as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            try? FileManager.default.removeItem(at: destinationURL)
            throw PhotoExportError.cannotFinishFile
        }
        return destinationURL
    }

    static func discardTemporaryCopy(_ url: URL, original: CapturedPhoto) {
        let directory = original.fileURL.deletingLastPathComponent().standardizedFileURL
        guard url.standardizedFileURL != original.fileURL.standardizedFileURL,
              url.deletingLastPathComponent().standardizedFileURL == directory,
              url.lastPathComponent.hasPrefix("fielens-share-"),
              url.pathExtension.lowercased() == "jpg" else {
            return
        }
        try? FileManager.default.removeItem(at: url)
    }
}
