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
        case .original: "Sin reducir ni recodificar · Conserva los metadatos"
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
/// Metadata for the actual JPEG the user is reviewing and will share.
/// The camera's untouched full-resolution file is kept separately until Repetir.
nonisolated struct PreparedPhoto: Sendable {
    let fileURL: URL
    let resolution: ExportResolution
    let pixelWidth: Int
    let pixelHeight: Int
    let byteCount: Int
    let didFrameObject: Bool

    var megapixels: Double {
        Double(pixelWidth) * Double(pixelHeight) / 1_000_000
    }
}

nonisolated enum PhotoExportService {
    /// Prepares the visible result. Its exact bytes will later go to the share sheet.
    /// Called off MainActor: ImageIO decoding or encoding can take time.
    static func prepareForReview(
        photo: CapturedPhoto,
        resolution: ExportResolution,
        frameObject: Bool = false
    ) throws -> PreparedPhoto {
        let prepared = try prepareInternal(
            photo: photo,
            resolution: resolution,
            frameObject: frameObject
        )
        let url = prepared.url
        do {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let rawProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary?,
                  let width = (rawProperties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
                  let height = (rawProperties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
                  width > 0, height > 0 else {
                throw PhotoExportError.invalidSource
            }
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let bytes = attrs[.size] as? NSNumber else {
                throw PhotoExportError.invalidSource
            }
            return PreparedPhoto(
                fileURL: url,
                resolution: resolution,
                pixelWidth: width,
                pixelHeight: height,
                byteCount: bytes.intValue,
                didFrameObject: prepared.didFrame
            )
        } catch {
            discardTemporaryCopy(url, original: photo)
            throw error
        }
    }


    static func prepare(photo: CapturedPhoto, resolution: ExportResolution) throws -> URL {
        try prepareInternal(photo: photo, resolution: resolution, frameObject: false).url
    }

    private static func prepareInternal(
        photo: CapturedPhoto,
        resolution: ExportResolution,
        frameObject: Bool
    ) throws -> (url: URL, didFrame: Bool) {
        // Exact original, including its metadata, remains available when requested.
        guard resolution.maximumLongEdge != nil else {
            guard FileManager.default.fileExists(atPath: photo.fileURL.path) else {
                throw PhotoExportError.invalidSource
            }
            return (photo.fileURL, false)
        }

        guard let source = CGImageSourceCreateWithURL(photo.fileURL as CFURL, nil),
              CGImageSourceGetCount(source) > 0 else {
            throw PhotoExportError.invalidSource
        }

        // Framing must happen BEFORE reducing the OBJECT to its final size.
        // Otherwise a small document in a large scene could lose most of its
        // available pixels when cropped from an already 1600px-wide full frame.
        let desiredLongEdge = resolution.expectedLongEdge(for: photo)
        let workingLongEdge = frameObject
            ? min(4800, max(desiredLongEdge * 2, 3200))
            : desiredLongEdge

        func makeThumbnail(maximumEdge: Int) -> CGImage? {
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maximumEdge,
                kCGImageSourceShouldCacheImmediately: true
            ]
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        }

        guard let thumbnail = makeThumbnail(maximumEdge: workingLongEdge) else {
            throw PhotoExportError.cannotCreateImage
        }

        // Detect on the STILL photo rather than the old preview frame.
        // Bound the working raster to protect memory on older iPhones.
        var renderedImage = thumbnail
        var didFrameObject = false
        if frameObject,
           let surface = SurfacePhotoProcessor.bestSurface(in: thumbnail),
           let framed = SurfacePhotoProcessor.rectifiedImage(
               from: thumbnail,
               surface: surface,
               maximumLongEdge: desiredLongEdge
           ) {
            renderedImage = framed
            didFrameObject = true
        } else if workingLongEdge > desiredLongEdge {
            // No valid rectangle: preserve the whole frame but STILL obey
            // the chosen Ligera/Compartir/Detalle resolution.
            guard let fallback = makeThumbnail(maximumEdge: desiredLongEdge) else {
                throw PhotoExportError.cannotCreateImage
            }
            renderedImage = fallback
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
        CGImageDestinationAddImage(destination, renderedImage, jpegOptions as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            try? FileManager.default.removeItem(at: destinationURL)
            throw PhotoExportError.cannotFinishFile
        }
        return (destinationURL, didFrameObject)
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
