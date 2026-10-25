import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var camera = CameraViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreview(session: camera.session)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            LinearGradient(
                colors: [.black.opacity(0.58), .clear, .black.opacity(0.60)],
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
                    Text("DEV 0.1.1")
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.75))
                }
                .foregroundStyle(.white)

                Spacer()

                statusPanel

                Text("Prueba de cámara · Sin fotografías ni datos guardados")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(24)
        }
        .onAppear {
            if scenePhase == .active {
                camera.start()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                camera.start()
            } else {
                camera.stop()
            }
        }
        .onDisappear {
            camera.stop()
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
            statusMessage("Cámara activa", symbol: "checkmark.circle.fill")

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

#Preview {
    ContentView()
}
