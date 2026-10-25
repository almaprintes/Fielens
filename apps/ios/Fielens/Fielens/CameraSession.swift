import AVFoundation
import Foundation

/// Owns all mutable AVCaptureSession configuration on one serial queue.
/// The preview layer reads the session; configuration/start/stop never run on the UI thread.
/// This is the first camera-only spike: no photos or recordings are stored.
nonisolated final class CameraSession: @unchecked Sendable {
    let session = AVCaptureSession()

    private let queue = DispatchQueue(label: "com.almaprintes.fielens.camera.session")
    private var isConfigured = false

    func start(completion: @escaping @MainActor (Bool, String?) -> Void) {
        queue.async { [self] in
            if !isConfigured {
                if let message = configureOnQueue() {
                    Task { @MainActor in
                        completion(false, message)
                    }
                    return
                }
                isConfigured = true
            }

            if !session.isRunning {
                session.startRunning()
            }

            let didStart = session.isRunning
            Task { @MainActor in
                completion(didStart, didStart ? nil : "No se ha podido iniciar la cámara.")
            }
        }
    }

    func stop() {
        queue.async { [self] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    /// Called exclusively on `queue`.
    private func configureOnQueue() -> String? {
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            return "No se ha encontrado una cámara trasera disponible."
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)

            session.beginConfiguration()
            defer { session.commitConfiguration() }

            session.sessionPreset = .photo

            guard session.canAddInput(input) else {
                return "No se ha podido conectar la cámara."
            }
            session.addInput(input)
            return nil
        } catch {
            return "No se ha podido configurar la cámara."
        }
    }
}
