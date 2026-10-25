import AVFoundation
import Combine
import SwiftUI

enum CameraStatus: Equatable {
    case idle
    case requestingPermission
    case starting
    case running
    case denied
    case unavailable(String)
}

/// Coordinates camera permissions, captures and UI state on MainActor.
/// Photo bytes remain unmodified in a private temporary JPEG file.
@MainActor
final class CameraViewModel: ObservableObject {
    @Published private(set) var status: CameraStatus = .idle
    @Published private(set) var photo: CapturedPhoto?
    @Published private(set) var isCapturing = false
    @Published private(set) var captureErrorMessage: String?

    private let cameraSession = CameraSession()
    private var isRequestingPermission = false
    private var shouldRun = false
    private var runID = 0

    var session: AVCaptureSession { cameraSession.session }

    init() {
        // Avoid keeping captured documents on disk across separate app launches.
        TemporaryPhotoStore.clearPreviousLaunch()
    }

    func start() {
        guard photo == nil else { return }
        shouldRun = true
        guard !isRequestingPermission else { return }
        guard status != .running && status != .starting else { return }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            beginSession()

        case .notDetermined:
            isRequestingPermission = true
            status = .requestingPermission
            Task { [weak self] in
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                guard let self else { return }
                self.isRequestingPermission = false
                guard self.shouldRun else { return }
                if granted {
                    self.beginSession()
                } else {
                    self.status = .denied
                }
            }

        case .denied, .restricted:
            status = .denied

        @unknown default:
            status = .unavailable("Estado de autorización desconocido.")
        }
    }

    func stop() {
        shouldRun = false
        runID += 1
        cameraSession.stop()
        if status == .running || status == .starting {
            status = .idle
        }
    }

    func capturePhoto() {
        guard status == .running && !isCapturing && photo == nil else { return }
        isCapturing = true
        captureErrorMessage = nil

        cameraSession.capture { [weak self] result in
            guard let self else {
                if case .success(let captured) = result {
                    TemporaryPhotoStore.discard(captured)
                }
                return
            }

            self.isCapturing = false
            switch result {
            case .success(let captured):
                self.photo = captured
                self.stop() // No running preview or battery use while reviewing.
            case .failure(let error):
                self.captureErrorMessage = error.localizedDescription
            }
        }
    }

    func retake() {
        if let previous = photo {
            TemporaryPhotoStore.discard(previous)
        }
        photo = nil
        captureErrorMessage = nil
        isCapturing = false
        status = .idle
        start()
    }

    func clearCaptureError() {
        captureErrorMessage = nil
    }

    private func beginSession() {
        guard shouldRun else { return }
        runID += 1
        let requestedRun = runID
        status = .starting
        cameraSession.start { [weak self] started, errorMessage in
            guard let self, self.shouldRun, self.runID == requestedRun else { return }
            self.status = started
                ? .running
                : .unavailable(errorMessage ?? "La cámara no está disponible.")
        }
    }
}
