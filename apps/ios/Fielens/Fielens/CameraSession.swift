import AVFoundation
import Foundation

/// All mutable session configuration and capture requests belong to one serial queue.
/// Never block the SwiftUI main actor on startRunning / stopRunning.
nonisolated final class CameraSession: @unchecked Sendable {
    let session = AVCaptureSession()

    private let queue = DispatchQueue(label: "com.almaprintes.fielens.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private var captureDelegate: PhotoCaptureDelegate?
    private var maximumDimensions: CMVideoDimensions?

    func start(completion: @escaping @MainActor @Sendable (Bool, String?) -> Void) {
        queue.async { [self] in
            if !isConfigured {
                if let message = configureOnQueue() {
                    Task { @MainActor in completion(false, message) }
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

    func capture(completion: @escaping @MainActor @Sendable (Result<CapturedPhoto, CameraCaptureError>) -> Void) {
        queue.async { [self] in
            guard isConfigured && session.isRunning else {
                Task { @MainActor in
                    completion(.failure(.failed("La cámara todavía no está lista.")))
                }
                return
            }
            guard captureDelegate == nil else {
                Task { @MainActor in
                    completion(.failure(.failed("Ya hay una fotografía en curso.")))
                }
                return
            }
            guard photoOutput.availablePhotoCodecTypes.contains(.jpeg) else {
                Task { @MainActor in
                    completion(.failure(.failed("Este dispositivo no permite capturar en JPEG.")))
                }
                return
            }

            let settings = AVCapturePhotoSettings(format: [
                AVVideoCodecKey: AVVideoCodecType.jpeg
            ])
            if let maximumDimensions {
                settings.maxPhotoDimensions = maximumDimensions
            }
            settings.photoQualityPrioritization = .quality
            settings.flashMode = .off

            let delegate = PhotoCaptureDelegate { [weak self] result in
                guard let self else { return }
                self.queue.async { [self] in
                    self.captureDelegate = nil
                    Task { @MainActor in completion(result) }
                }
            }
            captureDelegate = delegate
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    /// Runs exclusively on `queue`; returns an explanation instead of crashing on failure.
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
            session.sessionPreset = .photo

            guard session.canAddInput(input) else {
                session.commitConfiguration()
                return "No se ha podido conectar la cámara."
            }
            session.addInput(input)

            guard session.canAddOutput(photoOutput) else {
                session.commitConfiguration()
                return "Este dispositivo no admite fotografías en esta sesión."
            }
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality

            session.commitConfiguration()

            // Use the largest dimensions supported by the actual active camera format.
            // This must be configured before startRunning, not on each shutter press.
            if let largest = device.activeFormat.supportedMaxPhotoDimensions.max(by: {
                Int64($0.width) * Int64($0.height) < Int64($1.width) * Int64($1.height)
            }) {
                photoOutput.maxPhotoDimensions = largest
                maximumDimensions = largest
            }
            return nil
        } catch {
            return "No se ha podido configurar la cámara."
        }
    }
}

/// AVFoundation sends delegate events off the UI thread. Data is flattened before
/// crossing to MainActor, and the delegate is strongly held until capture finishes.
nonisolated final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private let finish: @Sendable (Result<CapturedPhoto, CameraCaptureError>) -> Void
    private var processed: Result<CapturedPhoto, CameraCaptureError>?

    init(finish: @escaping @Sendable (Result<CapturedPhoto, CameraCaptureError>) -> Void) {
        self.finish = finish
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if error != nil {
            processed = .failure(.failed("La cámara no pudo procesar la fotografía."))
            return
        }
        guard let data = photo.fileDataRepresentation() else {
            processed = .failure(.failed("No se han recibido datos de la fotografía."))
            return
        }
        do {
            processed = .success(try TemporaryPhotoStore.saveOriginalJPEG(data))
        } catch {
            processed = .failure(.failed("No se ha podido guardar la captura temporal."))
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {
        if error != nil {
            if case .success(let photo) = processed {
                TemporaryPhotoStore.discard(photo)
            }
            finish(.failure(.failed("No se ha podido completar la fotografía.")))
        } else {
            finish(processed ?? .failure(.failed("La cámara no ha devuelto una imagen.")))
        }
    }
}
