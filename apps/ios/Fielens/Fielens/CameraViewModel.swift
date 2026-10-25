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

/// Coordinates permissions and status on MainActor, and camera operations on a serial queue.
@MainActor
final class CameraViewModel: ObservableObject {
    @Published private(set) var status: CameraStatus = .idle

    private let cameraSession = CameraSession()
    private var isRequestingPermission = false
    private var shouldRun = false
    private var runID = 0

    var session: AVCaptureSession { cameraSession.session }

    func start() {
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
