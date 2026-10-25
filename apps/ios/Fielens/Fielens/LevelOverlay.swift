import SwiftUI

/// A two-axis on-screen indicator for the phone's orientation to the horizontal.
/// This is not a perspective detector and does not certify perpendicularity to the paper.
struct LevelOverlay: View {
    let status: LevelSensorStatus
    let reading: LevelReading?

    private var aligned: Bool { reading?.isWithinExperimentalTolerance == true }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.62))
                        .overlay(Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1))
                    Rectangle().fill(.white.opacity(0.33))
                        .frame(width: 1, height: 98)
                    Rectangle().fill(.white.opacity(0.33))
                        .frame(width: 98, height: 1)
                    Circle().strokeBorder(.white.opacity(0.45), lineWidth: 1)
                        .frame(width: 52, height: 52)

                    Circle()
                        .fill(aligned ? Color.green : Color.orange)
                        .frame(width: 21, height: 21)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        .offset(x: dotX, y: dotY)
                }
                .frame(width: 116, height: 116)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text("NIVEL DIGITAL")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                    if let reading {
                        Text(String(format: "Eje X: %+.1f°", reading.xDegrees))
                            .monospacedDigit()
                        Text(String(format: "Eje Y: %+.1f°", reading.yDegrees))
                            .monospacedDigit()
                        Text(aligned ? "Alineado con el horizonte" : "Ajusta la inclinación")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(aligned ? .green : .orange)
                    } else {
                        Text(statusDescription)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("Referencia: gravedad · No mide el ángulo de la superficie")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.88))
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    private var dotX: CGFloat {
        // A virtual bubble moves opposite the gravity vector projected onto the phone.
        CGFloat(-min(12.0, max(-12.0, reading?.xDegrees ?? 0))) * 3
    }

    private var dotY: CGFloat {
        CGFloat(min(12.0, max(-12.0, reading?.yDegrees ?? 0))) * 3
    }

    private var statusDescription: String {
        switch status {
        case .idle, .waiting:
            "Esperando sensores…"
        case .active:
            "Sin lectura válida"
        case .invalidPose:
            "Orienta la pantalla hacia arriba"
        case .unavailable:
            "Sensores de movimiento no disponibles"
        }
    }
}
