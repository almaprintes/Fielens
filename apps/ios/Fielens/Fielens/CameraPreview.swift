import AVFoundation
import SwiftUI
import UIKit

/// Camera preview and prototype Vision overlay. No preview frames are saved.
/// Each Vision coordinate is normalized bottom-left and must map through the
/// preview layer's own capture-device conversion (including aspect-fill crop).
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var surfaces: [DetectedSurface] = []
    var selectedSurfaceID: UUID?
    var onSurfaceTap: ((SurfacePoint) -> Void)?

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        view.surfaces = surfaces
        view.selectedSurfaceID = selectedSurfaceID
        view.onSurfaceTap = onSurfaceTap
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
        uiView.surfaces = surfaces
        uiView.selectedSurfaceID = selectedSurfaceID
        uiView.onSurfaceTap = onSurfaceTap
        uiView.updateContours()
    }
}

final class PreviewView: UIView {
    var surfaces: [DetectedSurface] = []
    var selectedSurfaceID: UUID?
    var onSurfaceTap: ((SurfacePoint) -> Void)?

    private let suggestionLayer = CAShapeLayer()
    private let selectionLayer = CAShapeLayer()

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureOverlay()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureOverlay()
    }

    private func configureOverlay() {
        suggestionLayer.fillColor = UIColor.clear.cgColor
        suggestionLayer.strokeColor = UIColor.white.withAlphaComponent(0.85).cgColor
        suggestionLayer.lineWidth = 2
        suggestionLayer.lineJoin = .round
        suggestionLayer.lineDashPattern = [6, 5]

        selectionLayer.fillColor = UIColor.systemMint.withAlphaComponent(0.10).cgColor
        selectionLayer.strokeColor = UIColor.systemMint.cgColor
        selectionLayer.lineWidth = 3
        selectionLayer.lineJoin = .round

        layer.addSublayer(suggestionLayer)
        layer.addSublayer(selectionLayer)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPreview(_:))))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        suggestionLayer.frame = bounds
        selectionLayer.frame = bounds
        updateContours()
    }

    /// Mapping is provisional until measured against a physical A4 reference.
    /// The detector's .right orientation expects a rear camera in portrait.
    func updateContours() {
        let suggestions = UIBezierPath()
        let selected = UIBezierPath()

        for surface in surfaces where surface.isValid {
            let path = selectedSurfaceID == surface.id ? selected : suggestions
            let points = surface.corners.map { corner in
                previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(
                    x: corner.x,
                    y: 1.0 - corner.y
                ))
            }
            guard let first = points.first else { continue }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.close()
        }

        suggestionLayer.path = suggestions.cgPath
        selectionLayer.path = selected.cgPath
    }

    @objc private func didTapPreview(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        let viewPoint = recognizer.location(in: self)
        let capturePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: viewPoint)
        let normalized = SurfacePoint(
            x: Double(capturePoint.x),
            y: Double(1.0 - capturePoint.y)
        )
        guard normalized.isNormalized else { return }
        onSurfaceTap?(normalized)
    }
}
