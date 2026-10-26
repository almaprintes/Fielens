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
    @Published private(set) var surfaceCandidates: [DetectedSurface] = []
    @Published private(set) var selectedSurfaceID: UUID?
    @Published private(set) var correctedSurfaceCorners: [UUID: [SurfaceViewPoint]] = [:]
    @Published private(set) var pendingSurfaceTap: SurfacePendingTap?
    @Published private(set) var isScanningSurface = false
    @Published private(set) var surfaceMessage = "Toca el objeto o pulsa Buscar contorno."

    private let cameraSession = CameraSession()
    private var isRequestingPermission = false
    private var shouldRun = false
    private var runID = 0
    private var scanID = 0

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
        scanID += 1
        isScanningSurface = false
        surfaceCandidates = []
        selectedSurfaceID = nil
        correctedSurfaceCorners = [:]
        pendingSurfaceTap = nil
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

    func scanSurfaces(selecting touchedPoint: SurfaceViewPoint? = nil) {
        guard status == .running && photo == nil && !isScanningSurface else { return }
        isScanningSurface = true
        surfaceCandidates = []
        selectedSurfaceID = nil
        correctedSurfaceCorners = [:]
        pendingSurfaceTap = touchedPoint.map { SurfacePendingTap(id: UUID(), point: $0) }
        surfaceMessage = "Buscando rectángulos…"
        scanID += 1
        let expectedScan = scanID
        let expectedRun = runID

        cameraSession.scanSurfaces { [weak self] result in
            guard let self, self.shouldRun, self.status == .running,
                  self.runID == expectedRun, self.scanID == expectedScan else {
                return
            }
            self.isScanningSurface = false
            switch result {
            case .success(let candidates):
                self.surfaceCandidates = candidates
                if candidates.isEmpty {
                    self.pendingSurfaceTap = nil
                    self.surfaceMessage = "No se detectó un rectángulo. Mejora luz o encuadre y prueba otra vez."
                } else if touchedPoint != nil {
                    // PreviewView will select by screen-space hit testing using
                    // the EXACT same projected polygons that it draws.
                    self.surfaceMessage = "Comprobando qué contorno coincide con tu toque…"
                } else {
                    self.surfaceMessage = "Detectados \(candidates.count) contornos. Toca la hoja, no los cuadros interiores."
                }
            case .failure(let error):
                self.pendingSurfaceTap = nil
                self.surfaceMessage = error.localizedDescription
            }
        }
    }

    func surfaceTapped(at point: SurfaceViewPoint, matching renderedSurfaceID: UUID?) {
        guard status == .running, !isScanningSurface else { return }
        if let renderedSurfaceID,
           surfaceCandidates.contains(where: { $0.id == renderedSurfaceID }) {
            pendingSurfaceTap = nil
            selectedSurfaceID = renderedSurfaceID
            surfaceMessage = "Contorno seleccionado · No mide perpendicularidad. Repite búsqueda si mueves el móvil."
        } else {
            // A one-step tap asks Vision for a fresh frame and then resolves the
            // original touch against the actual polygons DRAWN by PreviewView.
            scanSurfaces(selecting: point)
        }
    }

    func resolvePendingSurfaceTap(requestID: UUID, renderedSurfaceID: UUID?) {
        guard pendingSurfaceTap?.id == requestID else { return }
        pendingSurfaceTap = nil
        guard let renderedSurfaceID,
              surfaceCandidates.contains(where: { $0.id == renderedSurfaceID }) else {
            surfaceMessage = "Ese punto no pertenece a un contorno detectado. Toca el borde de la hoja o busca de nuevo."
            return
        }
        selectedSurfaceID = renderedSurfaceID
        surfaceMessage = "Contorno seleccionado · No mide perpendicularidad. Repite búsqueda si mueves el móvil."
    }

    func applyManualCornerAdjustment(surfaceID: UUID, corners: [SurfaceViewPoint]) {
        guard selectedSurfaceID == surfaceID,
              surfaceCandidates.contains(where: { $0.id == surfaceID }),
              SurfaceScreenPolygon(id: surfaceID, corners: corners).isConvex else { return }
        correctedSurfaceCorners[surfaceID] = corners
        surfaceMessage = "Contorno ajustado manualmente. No mide perpendicularidad."
    }

    func resetManualCornerAdjustment() {
        guard let selectedSurfaceID else { return }
        correctedSurfaceCorners.removeValue(forKey: selectedSurfaceID)
        surfaceMessage = "Ajuste restablecido. Arrastra las esquinas para corregirlas."
    }

    func selectAnotherSurface() {
        guard surfaceCandidates.count > 1 else { return }
        let ordered = surfaceCandidates.sorted { $0.areaFraction > $1.areaFraction }
        let currentIndex = ordered.firstIndex { $0.id == selectedSurfaceID } ?? -1
        selectedSurfaceID = ordered[(currentIndex + 1) % ordered.count].id
        pendingSurfaceTap = nil
        surfaceMessage = "Otro contorno seleccionado. Comprueba que coincide con el objeto."
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
