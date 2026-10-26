import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var camera = CameraViewModel()
    @StateObject private var level = LevelMotionModel()
    @State private var exportResolution: ExportResolution = .share
    @State private var showingResolutionSheet = false
    @State private var frameDetectedObject = true
    @State private var isAdjustingSurface = false
    @State private var isCameraOpen = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if !isCameraOpen {
                welcomeScreen
            } else if let photo = camera.photo {
                PhotoReviewView(
                    photo: photo,
                    selectedResolution: $exportResolution,
                    frameDetectedObject: $frameDetectedObject,
                    onRetake: camera.retake,
                    onGoHome: closeCamera
                )
            } else {
                liveCamera
            }
        }
        .sheet(isPresented: $showingResolutionSheet) {
            ResolutionSelectionSheet(selectedResolution: $exportResolution)
        }
        .onAppear {
            if isCameraOpen && scenePhase == .active {
                camera.start()
                if camera.photo == nil { level.start() }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                if isCameraOpen {
                    camera.start()
                    if camera.photo == nil { level.start() }
                }
            } else {
                camera.stop()
                level.stop()
            }
        }
        .onChange(of: camera.photo?.id) { newPhotoID in
            if isCameraOpen && newPhotoID == nil && scenePhase == .active {
                level.start()
            } else {
                level.stop()
            }
        }
        .onChange(of: camera.selectedSurfaceID) { selectedID in
            if selectedID == nil { isAdjustingSurface = false }
        }
        .onChange(of: isAdjustingSurface) { editing in
            camera.setCornerEditing(editing)
        }
        .onDisappear {
            camera.stop()
            level.stop()
        }
    }

    // No camera session or sensor updates are started on the home screen.
    // Only an explicit user interaction opens the camera.
    private var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 28)

            ZStack {
                Circle()
                    .fill(Color(red: 0.85, green: 0.79, blue: 0.68).opacity(0.14))
                    .frame(width: 170, height: 170)
                Circle()
                    .strokeBorder(
                        Color(red: 0.86, green: 0.78, blue: 0.64).opacity(0.6),
                        lineWidth: 1
                    )
                    .frame(width: 136, height: 136)
                Image(systemName: "camera.aperture")
                    .font(.system(size: 74, weight: .ultraLight))
                    .foregroundStyle(Color(red: 0.91, green: 0.84, blue: 0.72))
            }
            .accessibilityHidden(true)

            Text("Fielens")
                .font(.system(size: 43, weight: .light, design: .serif))
                .tracking(1.5)
                .foregroundStyle(Color(red: 0.95, green: 0.90, blue: 0.82))
                .padding(.top, 26)

            Text("FOTOGRAFÍAS FIELES, SIN COMPLICACIONES")
                .font(.caption.weight(.medium))
                .tracking(1.2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.65))
                .padding(.top, 12)

            Text("Encuadra documentos, fotografías y otras superficies con ayuda del nivel y la detección automática.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 20)
                .padding(.top, 24)

            Spacer(minLength: 38)

            VStack(spacing: 16) {
                Button {
                    isCameraOpen = true
                    if scenePhase == .active {
                        camera.start()
                        level.start()
                    }
                } label: {
                    Label("Abrir cámara", systemImage: "camera")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.86, green: 0.78, blue: 0.64))
                .foregroundStyle(.black)

                Button {
                    showingResolutionSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Resolución de foto")
                        Spacer(minLength: 4)
                        Text(exportResolution.title)
                            .foregroundStyle(.white.opacity(0.7))
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .padding(16)
                    .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
            }

            Spacer(minLength: 25)

            Text("Las imágenes se procesan en tu iPhone.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.63))
            Text("DEV 0.1.13")
                .font(.caption.monospaced())
                .foregroundStyle(.white.opacity(0.38))
                .padding(.top, 10)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private func closeCamera() {
        isCameraOpen = false
        isAdjustingSurface = false
        camera.endSession()
        level.stop()
    }

    private var liveCamera: some View {
        ZStack {
            CameraPreview(
                session: camera.session,
                surfaces: camera.surfaceCandidates,
                selectedSurfaceID: camera.selectedSurfaceID,
                pendingTap: camera.pendingSurfaceTap,
                isEditingCorners: isAdjustingSurface,
                correctedCornersByID: camera.correctedSurfaceCorners,
                onSurfaceTap: { point, renderedSurfaceID in
                    camera.surfaceTapped(at: point, matching: renderedSurfaceID)
                },
                onScanTapResolved: { requestID, renderedSurfaceID in
                    camera.resolvePendingSurfaceTap(
                        requestID: requestID,
                        renderedSurfaceID: renderedSurfaceID
                    )
                },
                onCornerAdjusted: { surfaceID, corners in
                    camera.applyManualCornerAdjustment(surfaceID: surfaceID, corners: corners)
                }
            )
                .ignoresSafeArea()
                .accessibilityHidden(true)

            LinearGradient(
                colors: [.black.opacity(0.60), .clear, .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .opacity(isAdjustingSurface ? 0 : 1)
            .allowsHitTesting(false)

            VStack(spacing: 18) {
                HStack(spacing: 8) {
                    Button(action: closeCamera) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.plain)
                    .disabled(camera.isCapturing)
                    .accessibilityLabel("Volver al inicio")
                    Image(systemName: "viewfinder")
                        .foregroundStyle(.mint)
                    Text("FIELENS")
                        .font(.headline)
                        .tracking(2)
                    Spacer()
                    Text("DEV 0.1.13")
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.8))
                }
                .foregroundStyle(.white)

                // Keep the alignment indicator high and compact so the surface
                // underneath stays visible while selecting a contour.
                LevelOverlay(status: level.status, reading: level.reading)

                Spacer(minLength: 14)

                // Detection starts automatically with the camera.
                // A tiny correction menu replaces the previous manual workflow.
                HStack(spacing: 10) {
                    Image(systemName: camera.selectedSurfaceID == nil
                          ? "viewfinder"
                          : "viewfinder.circle.fill")
                        .foregroundStyle(.mint)
                        .font(.body.weight(.semibold))
                    Text(camera.surfaceMessage)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if camera.selectedSurfaceID != nil {
                        Menu {
                            if camera.surfaceCandidates.count > 1 {
                                Button("Elegir otro contorno", systemImage: "square.on.square") {
                                    camera.selectAnotherSurface()
                                }
                            }
                            Button("Corregir esquinas", systemImage: "crop.rotate") {
                                isAdjustingSurface = true
                            }
                            Button("Buscar de nuevo", systemImage: "arrow.clockwise") {
                                camera.scanSurfaces()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.86))
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Opciones para corregir el contorno")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.black.opacity(0.46), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .contain)


                statusPanel

                Button {
                    showingResolutionSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.mint)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("RESOLUCIÓN DE FOTO")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white.opacity(0.7))
                            Text(exportResolution.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Elegir resolución: \(exportResolution.title)")
                .accessibilityHint("Abre cuatro tamaños de archivo para compartir")

                if camera.status == .running {
                    Button(action: camera.capturePhoto) {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 3)
                                .frame(width: 80, height: 80)
                            Circle()
                                .fill(.white)
                                .frame(width: 64, height: 64)
                        }
                    }
                    .disabled(camera.isCapturing)
                    .opacity(camera.isCapturing ? 0.5 : 1)
                    .accessibilityLabel("Hacer fotografía")
                    .accessibilityHint("Fotografía el soporte en su resolución nativa")
                    .padding(.vertical, 8)
                }

                if let error = camera.captureErrorMessage {
                    VStack(spacing: 6) {
                        Text(error).multilineTextAlignment(.center)
                        Button("Cerrar aviso", action: camera.clearCaptureError)
                            .font(.footnote)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.red.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                }

                Text("Captura original sin filtros · Solo se guarda temporalmente")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(24)
            .opacity(isAdjustingSurface ? 0 : 1)
            .allowsHitTesting(!isAdjustingSurface)

            if isAdjustingSurface, camera.selectedSurfaceID != nil {
                cornerAdjustmentControls
            }
        }
    }

    private var cornerAdjustmentControls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text("AJUSTAR ESQUINAS")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer(minLength: 4)
                Button("Restaurar") {
                    camera.resetManualCornerAdjustment()
                }
                .foregroundStyle(.white)
                Button("Listo") {
                    isAdjustingSurface = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
            .padding(10)
            .background(.black.opacity(0.76), in: RoundedRectangle(cornerRadius: 14))

            Text("Arrastra cada punto verde a la esquina real del papel. El ajuste no recorta la foto.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.black.opacity(0.70), in: RoundedRectangle(cornerRadius: 12))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var statusPanel: some View {
        switch camera.status {
        case .idle, .starting:
            statusMessage("Iniciando cámara…", symbol: "camera")
        case .requestingPermission:
            statusMessage("Esperando permiso de cámara…", symbol: "hand.raised")
        case .running:
            statusMessage(
                camera.isCapturing ? "Procesando fotografía…" : "Cámara activa",
                symbol: camera.isCapturing ? "hourglass" : "checkmark.circle.fill"
            )
        case .denied:
            VStack(spacing: 12) {
                statusMessage("Fielens necesita permiso para utilizar la cámara.", symbol: "camera.fill")
                Button("Abrir Ajustes") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
        case .unavailable(let message):
            VStack(spacing: 12) {
                statusMessage(message, symbol: "exclamationmark.triangle")
                Button("Reintentar") {
                    camera.stop()
                    camera.start()
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
        }
    }

    private func statusMessage(_ message: String, symbol: String) -> some View {
        Label(message, systemImage: symbol)
            .font(.subheadline.weight(.medium))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 14))
            .accessibilityElement(children: .combine)
    }
}

private struct PhotoReviewView: View {
    /// High-resolution camera source is kept untouched only for this session.
    let photo: CapturedPhoto
    @Binding var selectedResolution: ExportResolution
    @Binding var frameDetectedObject: Bool
    let onRetake: () -> Void
    let onGoHome: () -> Void
    @State private var preparedPhoto: PreparedPhoto?
    @State private var preparingResult = false
    @State private var preparationErrorMessage: String?
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var isSavingToPhotos = false
    @State private var photoSaveNotice: String?
    @State private var photoSaveFailed = false

    private var currentResult: PreparedPhoto? {
        guard let preparedPhoto, preparedPhoto.resolution == selectedResolution else {
            return nil
        }
        return preparedPhoto
    }

    /// Changes both on reselecting a quality and when capturing a new photo.
    private var reviewKey: String {
        photo.id.uuidString + "-" + selectedResolution.rawValue
            + "-" + String(frameDetectedObject)
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Button(action: onGoHome) {
                    Label("Inicio", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .disabled(isSavingToPhotos || showingShareSheet)
                .accessibilityLabel("Volver al inicio")
                Text("FIELENS")
                    .font(.headline)
                    .tracking(2)
                Spacer()
                Text("DEV 0.1.13")
                    .font(.caption.monospaced())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer(minLength: 0)

            if let result = currentResult,
               let image = UIImage(contentsOfFile: result.fileURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("Fotografía resultante a resolución \(selectedResolution.title)")
                    .padding(.horizontal, 10)
            } else if preparingResult {
                ProgressView("Preparando \(selectedResolution.title)…")
                    .tint(.mint)
                    .foregroundStyle(.white)
            } else if let preparationErrorMessage {
                ContentUnavailableView(
                    "No se pudo preparar la foto",
                    systemImage: "exclamationmark.triangle",
                    description: Text(preparationErrorMessage)
                )
                .foregroundStyle(.white)
            } else {
                ProgressView("Preparando fotografía…")
                    .tint(.mint)
            }

            Spacer(minLength: 0)

            VStack(spacing: 4) {
                if let result = currentResult {
                    Text("\(result.pixelWidth) × \(result.pixelHeight) píxeles · \(String(format: "%.2f", result.megapixels)) MP")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.white)
                    Text(ByteCountFormatter.string(fromByteCount: Int64(result.byteCount), countStyle: .file))
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(selectedResolution == .original
                         ? "Original íntegro · sin recortes"
                         : result.didFrameObject
                            ? "Objeto ajustado y enderezado · JPEG listo para compartir"
                            : frameDetectedObject
                                ? "No hubo contorno fiable · Imagen completa, sin recortar"
                                : "Imagen completa · JPEG listo para compartir")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Text("Calculando la resolución real del resultado…")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Picker("Resolución de la foto", selection: $selectedResolution) {
                    ForEach(ExportResolution.allCases) { choice in
                        Text(choice.title).tag(choice)
                    }
                }
                .pickerStyle(.menu)
                .tint(.mint)
                .disabled(isSavingToPhotos || showingShareSheet)
                Text(selectedResolution.recommendation)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.83))

                Toggle("Ajustar automáticamente al objeto", isOn: $frameDetectedObject)
                    .font(.subheadline)
                    .tint(.mint)
                    .foregroundStyle(.white)
                    .disabled(selectedResolution == .original || showingShareSheet || isSavingToPhotos)
                    .accessibilityHint("Recorta y corrige la perspectiva si Fielens detecta un rectángulo fiable")
                if selectedResolution == .original {
                    Text("Original siempre conserva el encuadre completo.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Button(action: retakeAndCleanup) {
                    Label("Repetir", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .disabled(isSavingToPhotos || showingShareSheet)

                Button {
                    guard let result = currentResult else { return }
                    // Share EXACTLY the same JPEG the user sees in review.
                    shareURL = result.fileURL
                    showingShareSheet = true
                } label: {
                    Label("Compartir", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
                .disabled(currentResult == nil || isSavingToPhotos)
            }
            .padding(.horizontal, 16)

            Button {
                saveCurrentResultToPhotos()
            } label: {
                Label(
                    isSavingToPhotos ? "Guardando en Fotos…" : "Guardar en Fotos",
                    systemImage: isSavingToPhotos ? "hourglass" : "square.and.arrow.down"
                )
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.mint)
            .disabled(currentResult == nil || isSavingToPhotos || showingShareSheet)
            .padding(.horizontal, 16)

            if let photoSaveNotice {
                Label(photoSaveNotice, systemImage: photoSaveFailed
                      ? "exclamationmark.triangle" : "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(photoSaveFailed ? Color.orange : Color.mint)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .accessibilityAddTraits(.updatesFrequently)
            }

            Text("Se encuadra el objeto automáticamente cuando es fiable. El original de cámara permanece temporalmente disponible.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .task(id: reviewKey) {
            await prepareSelectedResult()
        }
        .sheet(isPresented: $showingShareSheet, onDismiss: {
            shareURL = nil
        }) {
            if let shareURL {
                OriginalFileShareSheet(fileURL: shareURL)
            }
        }
        .onDisappear {
            // The original is deleted by CameraViewModel on Repetir.
            // Never delete a file while the native share sheet is using it.
            if !showingShareSheet, let preparedPhoto {
                PhotoExportService.discardTemporaryCopy(preparedPhoto.fileURL, original: photo)
            }
        }
    }

    private func prepareSelectedResult() async {
        photoSaveNotice = nil
        let source = photo
        let choice = selectedResolution
        let shouldFrame = frameDetectedObject
        let previous = preparedPhoto
        preparedPhoto = nil
        preparationErrorMessage = nil
        preparingResult = true

        // Release old derived JPEG before creating another; never remove the original.
        if let previous {
            PhotoExportService.discardTemporaryCopy(previous.fileURL, original: source)
        }

        do {
            let result = try await Task.detached(priority: .userInitiated) {
                try PhotoExportService.prepareForReview(
                    photo: source,
                    resolution: choice,
                    frameObject: shouldFrame
                )
            }.value

            guard !Task.isCancelled,
                  source.id == photo.id,
                  selectedResolution == choice,
                  frameDetectedObject == shouldFrame else {
                PhotoExportService.discardTemporaryCopy(result.fileURL, original: source)
                return
            }
            preparedPhoto = result
        } catch {
            if !Task.isCancelled {
                preparationErrorMessage = error.localizedDescription
            }
        }
        if !Task.isCancelled {
            preparingResult = false
        }
    }

    private func saveCurrentResultToPhotos() {
        guard let result = currentResult,
              !isSavingToPhotos, !showingShareSheet else { return }
        isSavingToPhotos = true
        photoSaveNotice = nil
        let urlToSave = result.fileURL
        Task {
            defer { isSavingToPhotos = false }
            do {
                try await PhotoLibrarySaver.saveJPEG(at: urlToSave)
                photoSaveFailed = false
                photoSaveNotice = "Fotografía guardada en Fotos."
            } catch {
                photoSaveFailed = true
                photoSaveNotice = error.localizedDescription
            }
        }
    }

    private func retakeAndCleanup() {
        if let preparedPhoto {
            PhotoExportService.discardTemporaryCopy(preparedPhoto.fileURL, original: photo)
        }
        preparedPhoto = nil
        onRetake()
    }
}

/// One explicit choice per row for the camera preview.
/// The already-working Picker in photo review remains unchanged.
private struct ResolutionSelectionSheet: View {
    @Binding var selectedResolution: ExportResolution
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Elige la resolución que verás después de fotografiar. La captura completa permanece disponible temporalmente para cambiar de calidad.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)

                    ForEach(ExportResolution.allCases) { choice in
                        Button {
                            selectedResolution = choice
                            dismiss()
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: choice == selectedResolution
                                      ? "checkmark.circle.fill"
                                      : "circle")
                                    .font(.title2)
                                    .foregroundStyle(choice == selectedResolution ? Color.mint : Color.secondary)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(choice.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(choice.recommendation)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                choice == selectedResolution
                                    ? Color.mint.opacity(0.14)
                                    : Color.secondary.opacity(0.10),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(choice.title). \(choice.recommendation)")
                        .accessibilityAddTraits(choice == selectedResolution ? .isSelected : [])
                    }
                }
                .padding(18)
            }
            .navigationTitle("Resolución de envío")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

/// Shares a *file* rather than a URL string or a re-encoded SwiftUI image.
/// Sharing is explicitly initiated by the user.
private struct OriginalFileShareSheet: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) { }
}

#Preview {
    ContentView()
}
