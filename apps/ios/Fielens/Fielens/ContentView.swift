import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var camera = CameraViewModel()
    @StateObject private var level = LevelMotionModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let photo = camera.photo {
                PhotoReviewView(photo: photo, onRetake: camera.retake)
            } else {
                liveCamera
            }
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
                    Text("DEV 0.1.3")
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.8))
                }
                .foregroundStyle(.white)

                Spacer()

                LevelOverlay(status: level.status, reading: level.reading)

                statusPanel

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
    let onRetake: () -> Void
    @State private var showingShareSheet = false

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("FIELENS")
                    .font(.headline)
                    .tracking(2)
                Spacer()
                Text("DEV 0.1.3")
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

            HStack(spacing: 12) {
                Button(action: onRetake) {
                    Label("Repetir", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button {
                    showingShareSheet = true
                } label: {
                    Label("Compartir original", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Text("La foto es temporal. Para conservarla, compártela o guárdala desde el menú.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .sheet(isPresented: $showingShareSheet) {
            OriginalFileShareSheet(fileURL: photo.fileURL)
        }
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
