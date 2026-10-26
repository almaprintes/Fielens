import Foundation
import Photos

/// Add-only Photos access: Fielens does not browse or read the user's library.
/// Save the exact JPEG currently shown in review, including its chosen crop
/// and resolution. The user's selection remains private to the device.
nonisolated enum PhotoLibrarySaveError: LocalizedError, Sendable {
    case denied
    case fileMissing
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .denied:
            "No tienes autorizado guardar fotos. Permite añadir fotos a Fielens desde Ajustes."
        case .fileMissing:
            "La fotografía seleccionada ya no está disponible."
        case .saveFailed:
            "No se pudo guardar la fotografía en Fotos. Vuelve a intentarlo."
        }
    }
}

@MainActor
enum PhotoLibrarySaver {
    static func saveJPEG(at fileURL: URL) async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw PhotoLibrarySaveError.fileMissing
        }

        var status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        guard status == .authorized || status == .limited else {
            throw PhotoLibrarySaveError.denied
        }

        // The file is not recompressed. PhotoKit copies this resource into
        // Photos, so crop, resolution and JPEG bytes come from review.
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = false
                request.addResource(with: .photo, fileURL: fileURL, options: options)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoLibrarySaveError.saveFailed)
                }
            }
        }
    }
}
