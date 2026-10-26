import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var camera = CameraViewModel()
    @StateObject private var level = LevelMotionModel()
    @State private var exportResolution: ExportResolution = .share
    @State private var showingResolutionSheet = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let photo = camera.photo {
                PhotoReviewView(photo: photo, selectedResolution: $exportResolution, onRetake: camera.retake)
            } else {
                liveCamera
            }
        }
        .sheet(isPresented: $showingResolutionSheet) {
            ResolutionSelectionSheet(selectedResolution: $exportResolution)
        }
        .onAppear {
            if scenePhase == .active {
                camera.start()
                if camera.photo == nil { level.start() }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                camera.start()
                if camera.photo == nil { level.start() }
            } else {
                camera.stop()
                level.stop()
            }
        }
        .onChange(of: camera.photo?.id) { newPhotoID in
            if newPhotoID == nil && scenePhase == .active {
                level.start()
            } else {
                level.stop()
            }
        }
        .onDisappear {
            camera.stop()
            level.stop()
        }
    }

    private var liveCamera: some View {
        ZStack {
            CameraPreview(
                session: camera.session,
                surfaces: camera.surfaceCandidates,
                selectedSurfaceID: camera.selectedSurfaceID,
                onSurfaceTap: { point in
                    camera.selectSurface(at: point)
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
            .allowsHitTesting(false)

            VStack(spacing: 18) {
                HStack(spacing: 8) {
                    Image(systemName: "viewfinder")
                        .foregroundStyle(.mint)
                    Text("FIELENS")
                        .font(.headline)
                        .tracking(2)
                    Spacer()
                    Text("DEV 0.1.6")
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.8))
                }
                .foregroundStyle(.white)

                Spacer()

                LevelOverlay(status: level.status, reading: level.reading)

                VStack(spacing: 6) {
                    Button {
                        camera.scanSurfaces()
                    } label: {
                        Label(
                            camera.isScanningSurface ? "Analizando…" : "Buscar contorno",
                            systemImage: camera.isScanningSurface
                                ? "hourglass"
                                : "viewfinder"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.mint)
                    .disabled(camera.status != .running || camera.isScanningSurface || camera.isCapturing)

                    Text(camera.surfaceMessage)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .foregroundStyle(.white)
                }
                .padding(10)
                .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 14))
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
        }
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
    let onRetake: () -> Void
    @State private var preparedPhoto: PreparedPhoto?
    @State private var preparingResult = false
    @State private var preparationErrorMessage: String?
    @State private var showingShareSheet = false
    @State private var shareURL: URL?

    private var currentResult: PreparedPhoto? {
        guard let preparedPhoto, preparedPhoto.resolution == selectedResolution else {
            return nil
        }
        return preparedPhoto
    }

    /// Changes both on reselecting a quality and when capturing a new photo.
    private var reviewKey: String { photo.id.uuidString + "-" + selectedResolution.rawValue }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("FIELENS")
                    .font(.headline)
                    .tracking(2)
                Spacer()
                Text("DEV 0.1.6")
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
                         ? "Original de cámara · Sin recortes ni recompresión"
                         : "Resultado \(selectedResolution.title) · JPEG listo para compartir")
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
                Text(selectedResolution.recommendation)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.83))
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
                .disabled(currentResult == nil)
            }
            .padding(.horizontal, 16)

            Text("El resultado mostrado es el archivo que se comparte. La captura completa queda temporalmente disponible por si cambias de calidad.")
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
        let source = photo
        let choice = selectedResolution
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
                try PhotoExportService.prepareForReview(photo: source, resolution: choice)
            }.value

            guard !Task.isCancelled,
                  source.id == photo.id,
                  selectedResolution == choice else {
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
