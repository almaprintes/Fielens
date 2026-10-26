import AVFoundation
import Foundation
import ImageIO
import Vision

nonisolated enum SurfaceScanError: Error, LocalizedError, Sendable {
    case unavailable
    case busy
    case failed

    var errorDescription: String? {
        switch self {
        case .unavailable: "No hay fotogramas de vídeo disponibles."
        case .busy: "Ya se está buscando una superficie."
        case .failed: "No se ha podido analizar el fotograma."
        }
    }
}

/// Analyses only a requested next frame. AVFoundation can continue to discard
/// every other buffer, avoiding a Vision request on each rendered camera frame.
///
/// Every access to pendingScan happens exclusively on sampleQueue.
/// No pixel buffers or personal photographs are saved or sent over the network.
nonisolated final class SurfaceFrameSampler: NSObject,
    AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {

    let sampleQueue = DispatchQueue(
        label: "com.almaprintes.fielens.camera.surface-sample",
        qos: .userInitiated
    )

    private var pendingScan:
        (@MainActor @Sendable (Result<[DetectedSurface], SurfaceScanError>) -> Void)?
    private var pendingScanID: UUID?

    func requestScan(
        completion: @escaping @MainActor @Sendable (Result<[DetectedSurface], SurfaceScanError>) -> Void
    ) {
        sampleQueue.async { [self] in
            guard pendingScan == nil else {
                Task { @MainActor in completion(.failure(.busy)) }
                return
            }
            let requestID = UUID()
            pendingScan = completion
            pendingScanID = requestID
            // Some devices may deliver no sample buffers despite a live preview.
            // Finish the request instead of leaving "Analizando…" indefinitely.
            sampleQueue.asyncAfter(deadline: .now() + .seconds(4)) { [self] in
                guard pendingScanID == requestID,
                      let timedOut = pendingScan else { return }
                pendingScan = nil
                pendingScanID = nil
                Task { @MainActor in timedOut(.failure(.unavailable)) }
            }
        }
    }

    func cancel() {
        sampleQueue.async { [self] in
            pendingScan = nil
            pendingScanID = nil
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let completion = pendingScan else { return }
        pendingScan = nil
        pendingScanID = nil

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            Task { @MainActor in completion(.failure(.unavailable)) }
            return
        }

        // Rear-camera sensor buffers are typically landscape-native. .right
        // makes Vision's coordinates upright for a PORTRAIT phone UI.
        // Landscape support and full coordinate calibration require iPhone QA.
        do {
            let rectangles = try RectangularSurfaceDetector.detect(
                in: pixelBuffer,
                orientation: .right
            )
            Task { @MainActor in completion(.success(rectangles)) }
        } catch {
            Task { @MainActor in completion(.failure(.failed)) }
        }
    }
}
