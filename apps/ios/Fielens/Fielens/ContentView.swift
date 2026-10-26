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
                PhotoReviewView(
                    photo: photo,
                    selectedResolution: $exportResolution,
                    onChooseResolution: { showingResolutionSheet = true },
                    onRetake: camera.retake
                )
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
            CameraPreview(session: camera.session)
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
                    Text("DEV 0.1.4")
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.8))
                }
                .foregroundStyle(.white)

                Spacer()

                LevelOverlay(status: level.status, reading: level.reading)

                statusPanel

                Button {
                    showingResolutionSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.mint)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("TAMAÑO AL COMPARTIR")
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
    let photo: CapturedPhoto
    @Binding var selectedResolution: ExportResolution
    let onChooseResolution: () -> Void
    let onRetake: () -> Void
    @State private var showingShareSheet = false
    @State private var isPreparing = false
    @State private var shareErrorMessage: String?
    @State private var temporaryShareURL: URL?

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("FIELENS")
                    .font(.headline)
                    .tracking(2)
                Spacer()
                Text("DEV 0.1.4")
                    .font(.caption.monospaced())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer(minLength: 0)

            if let image = UIImage(contentsOfFile: photo.fileURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("Fotografía original capturada")
                    .padding(.horizontal, 10)
            } else {
                ContentUnavailableView(
                    "No se puede previsualizar",
                    systemImage: "photo.badge.exclamationmark",
                    description: Text("No se han encontrado los datos de la captura.")
                )
                .foregroundStyle(.white)
            }

            Spacer(minLength: 0)

            VStack(spacing: 4) {
                Text("\(photo.pixelWidth) × \(photo.pixelHeight) píxeles · \(String(format: "%.2f", photo.megapixels)) MP")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white)
                Text(ByteCountFormatter.string(fromByteCount: Int64(photo.byteCount), countStyle: .file))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
                Text("JPEG original · Sin recortes, filtros ni recompresión")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Button(action: onChooseResolution) {
                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.mint)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tamaño para compartir")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(selectedResolution.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(selectedResolution.recommendation)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.white)
                }
                .padding(14)
                .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(isPreparing)
            .padding(.horizontal, 16)
            .accessibilityLabel("Cambiar resolución. Actual: \(selectedResolution.title)")

            if let shareErrorMessage {
                Text(shareErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            HStack(spacing: 12) {
                Button(action: onRetake) {
                    Label("Repetir", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .disabled(isPreparing)

                Button {
                    prepareAndShare()
                } label: {
                    Label(isPreparing ? "Preparando…" : "Compartir", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
                .disabled(isPreparing)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Text("El original permanece intacto en esta sesión. La copia para compartir puede tener menos resolución y no conserva los metadatos originales.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .sheet(isPresented: $showingShareSheet, onDismiss: clearTemporaryShare) {
            OriginalFileShareSheet(fileURL: temporaryShareURL ?? photo.fileURL)
        }
    }

    private func prepareAndShare() {
        guard !isPreparing else { return }
        shareErrorMessage = nil
        isPreparing = true
        let source = photo
        let choice = selectedResolution

        Task {
            do {
                let url = try await Task.detached(priority: .userInitiated) {
                    try PhotoExportService.prepare(photo: source, resolution: choice)
                }.value
                temporaryShareURL = url
                showingShareSheet = true
            } catch {
                shareErrorMessage = error.localizedDescription
            }
            isPreparing = false
        }
    }

    private func clearTemporaryShare() {
        if let temporaryShareURL {
            PhotoExportService.discardTemporaryCopy(temporaryShareURL, original: photo)
        }
        temporaryShareURL = nil
    }
}

/// One explicit, readable choice per row. Both camera and review use
/// the same selection state; no nested Picker inside Menu.
private struct ResolutionSelectionSheet: View {
    @Binding var selectedResolution: ExportResolution
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("La fotografía se captura a máxima resolución. Aquí eliges el tamaño de la copia que vas a enviar.")
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
        .presentationDetents([.medium, .large])
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
