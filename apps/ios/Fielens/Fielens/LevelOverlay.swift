import SwiftUI

/// Reference to gravity only. The indicator MUST NEVER present itself as
/// a calibrated perpendicularity guide to the photographed object.
struct LevelOverlay: View {
    let status: LevelSensorStatus
    let reading: LevelReading?

    @State private var expanded = false

    private var aligned: Bool { reading?.isWithinExperimentalTolerance == true }
    private var indicatorColor: Color { aligned ? .green : .orange }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                expanded.toggle()
            }
        } label: {
            Group {
                if expanded {
                    expandedContent
                } else {
                    compactContent
                }
            }
            .padding(expanded ? 12 : 10)
            .background(.black.opacity(0.69), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.20), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(expanded ? "Toca para reducir el nivel" : "Toca para ampliar el nivel")
    }

    private var compactContent: some View {
        HStack(spacing: 10) {
            bubble(diameter: 46)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("NIVEL")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                    if let reading {
                        Text(String(format: "X %+.1f°   Y %+.1f°", reading.xDegrees, reading.yDegrees))
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(indicatorColor)
                    } else {
                        Text(statusDescription)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(.white)

                Text("Gravedad · No indica perpendicularidad al objeto")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 2)
            Image(systemName: "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var expandedContent: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                bubble(diameter: 106)
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
                        Text(aligned ? "Cerca de horizontal" : "Ajusta la inclinación")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(indicatorColor)
                    } else {
                        Text(statusDescription)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.up")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Text("Referencia: gravedad · No mide la inclinación de la superficie")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.86))
                .multilineTextAlignment(.center)
        }
    }

    private func bubble(diameter: CGFloat) -> some View {
        let radius = diameter / 2
        let factor = diameter / 116 * 3

        return ZStack {
            Circle()
                .fill(.black.opacity(0.48))
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.48), lineWidth: 1)
                }
            Rectangle()
                .fill(.white.opacity(0.36))
                .frame(width: 1, height: diameter - 12)
            Rectangle()
                .fill(.white.opacity(0.36))
                .frame(width: diameter - 12, height: 1)
            Circle()
                .strokeBorder(.white.opacity(0.45), lineWidth: 1)
                .frame(width: radius, height: radius)
            Circle()
                .fill(indicatorColor)
                .frame(width: diameter < 60 ? 12 : 20, height: diameter < 60 ? 12 : 20)
                .overlay {
                    Circle()
                        .strokeBorder(.white, lineWidth: 1.5)
                }
                .offset(
                    x: CGFloat(-min(12, max(-12, reading?.xDegrees ?? 0))) * factor,
                    y: CGFloat(min(12, max(-12, reading?.yDegrees ?? 0))) * factor
                )
        }
        .frame(width: diameter, height: diameter)
    }

    private var accessibilitySummary: String {
        guard let reading else {
            return "Nivel gravitatorio. \(statusDescription). No mide perpendicularidad al objeto."
        }
        return String(
            format: "Nivel gravitatorio. Eje X %+.1f grados, eje Y %+.1f grados. No mide perpendicularidad al objeto.",
            reading.xDegrees,
            reading.yDegrees
        )
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
            "Sensores no disponibles"
        }
    }
}
