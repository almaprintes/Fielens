import AVFoundation
import SwiftUI
import UIKit

/// The same four projected vertices are used both to DRAW the contour
/// and to HIT-TEST a tap. This prevents a separate Vision -> touch mapping
/// from picking a different object than the one seen by the user.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var surfaces: [DetectedSurface] = []
    var selectedSurfaceID: UUID?
    var pendingTap: SurfacePendingTap?
    var isEditingCorners = false
    var correctedCornersByID: [UUID: [SurfaceViewPoint]] = [:]
    var onSurfaceTap: ((SurfaceViewPoint, UUID?) -> Void)?
    var onScanTapResolved: ((UUID, UUID?) -> Void)?
    var onCornerAdjusted: ((UUID, [SurfaceViewPoint]) -> Void)?

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        view.surfaces = surfaces
        view.selectedSurfaceID = selectedSurfaceID
        view.pendingTap = pendingTap
        view.isEditingCorners = isEditingCorners
        view.correctedCornersByID = correctedCornersByID
        view.onSurfaceTap = onSurfaceTap
        view.onScanTapResolved = onScanTapResolved
        view.onCornerAdjusted = onCornerAdjusted
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
        uiView.surfaces = surfaces
        uiView.selectedSurfaceID = selectedSurfaceID
        uiView.pendingTap = pendingTap
        uiView.isEditingCorners = isEditingCorners
        uiView.correctedCornersByID = correctedCornersByID
        uiView.onSurfaceTap = onSurfaceTap
        uiView.onScanTapResolved = onScanTapResolved
        uiView.onCornerAdjusted = onCornerAdjusted
        uiView.updateContours()
    }
}

final class PreviewView: UIView {
    var surfaces: [DetectedSurface] = []
    var selectedSurfaceID: UUID?
    var pendingTap: SurfacePendingTap?
    var isEditingCorners = false
    var correctedCornersByID: [UUID: [SurfaceViewPoint]] = [:]
    var onSurfaceTap: ((SurfaceViewPoint, UUID?) -> Void)?
    var onScanTapResolved: ((UUID, UUID?) -> Void)?
    var onCornerAdjusted: ((UUID, [SurfaceViewPoint]) -> Void)?

    private let handleLayer = CAShapeLayer()
    private var draggedCornerIndex: Int?
    private var draggedSurfaceID: UUID?
    private var uncommittedCorners: [SurfaceViewPoint]?
    private let suggestionLayer = CAShapeLayer()
    private let selectionLayer = CAShapeLayer()
    private var lastResolvedTapID: UUID?

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

        handleLayer.fillColor = UIColor.systemMint.cgColor
        handleLayer.strokeColor = UIColor.white.cgColor
        handleLayer.lineWidth = 3
        layer.addSublayer(handleLayer)

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPreview(_:))))
        let cornerDrag = UIPanGestureRecognizer(target: self, action: #selector(didPanCorner(_:)))
        cornerDrag.maximumNumberOfTouches = 1
        addGestureRecognizer(cornerDrag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        suggestionLayer.frame = bounds
        selectionLayer.frame = bounds
        handleLayer.frame = bounds
        updateContours()
    }

    private func projectedCorners(of surface: DetectedSurface) -> [CGPoint] {
        if surface.id == draggedSurfaceID, let uncommittedCorners,
           uncommittedCorners.count == 4 {
            return uncommittedCorners.map {
                CGPoint(x: $0.x * bounds.width, y: $0.y * bounds.height)
            }
        }
        if let saved = correctedCornersByID[surface.id], saved.count == 4 {
            return saved.map {
                CGPoint(x: $0.x * bounds.width, y: $0.y * bounds.height)
            }
        }
        return surface.corners.map { corner in
            let normalized = SurfaceCoordinateMapper.capturePoint(fromVision: corner)
            return previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(
                x: normalized.x,
                y: normalized.y
            ))
        }
    }

    private func renderedPolygons() -> [SurfaceScreenPolygon] {
        guard bounds.width > 0, bounds.height > 0 else { return [] }
        return surfaces.filter(\.isValid).map { surface in
            SurfaceScreenPolygon(
                id: surface.id,
                corners: projectedCorners(of: surface).map { point in
                    SurfaceViewPoint(
                        x: Double(point.x / bounds.width),
                        y: Double(point.y / bounds.height)
                    )
                }
            )
        }
    }

    private func hitTest(_ normalizedTouch: SurfaceViewPoint) -> UUID? {
        SurfaceScreenSelector.selected(at: normalizedTouch, from: renderedPolygons())
    }

    func updateContours() {
        let suggestions = UIBezierPath()
        let selected = UIBezierPath()

        for surface in surfaces where surface.isValid {
            let path = selectedSurfaceID == surface.id ? selected : suggestions
            let points = projectedCorners(of: surface)
            guard let first = points.first else { continue }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.close()
        }

        suggestionLayer.path = suggestions.cgPath
        selectionLayer.path = selected.cgPath

        let handles = UIBezierPath()
        if isEditingCorners, let selectedSurfaceID,
           let surface = surfaces.first(where: { $0.id == selectedSurfaceID }) {
            for point in projectedCorners(of: surface) {
                handles.append(UIBezierPath(
                    arcCenter: point,
                    radius: 11,
                    startAngle: 0,
                    endAngle: .pi * 2,
                    clockwise: true
                ))
            }
        }
        handleLayer.path = handles.cgPath
        resolvePendingTapWhenPossible()
    }

    private func resolvePendingTapWhenPossible() {
        guard !surfaces.isEmpty, let pendingTap,
              pendingTap.id != lastResolvedTapID,
              bounds.width > 0, bounds.height > 0 else { return }
        lastResolvedTapID = pendingTap.id

        let selectedID = hitTest(pendingTap.point)
        let requestID = pendingTap.id
        // Never mutate @Published SwiftUI model synchronously from updateUIView.
        DispatchQueue.main.async { [weak self] in
            self?.onScanTapResolved?(requestID, selectedID)
        }
    }

    @objc private func didTapPreview(_ recognizer: UITapGestureRecognizer) {
        guard !isEditingCorners, recognizer.state == .ended,
              bounds.width > 0, bounds.height > 0 else { return }
        let point = recognizer.location(in: self)
        let normalizedTouch = SurfaceViewPoint(
            x: Double(point.x / bounds.width),
            y: Double(point.y / bounds.height)
        )
        guard normalizedTouch.isFinite,
              (0...1).contains(normalizedTouch.x),
              (0...1).contains(normalizedTouch.y) else { return }
        // Crucially, we select the polygon that is ACTUALLY drawn under
        // this finger, not a separate converted point with another orientation.
        onSurfaceTap?(normalizedTouch, hitTest(normalizedTouch))
    }

    @objc private func didPanCorner(_ recognizer: UIPanGestureRecognizer) {
        guard isEditingCorners, bounds.width > 0, bounds.height > 0,
              let selectedSurfaceID,
              let surface = surfaces.first(where: { $0.id == selectedSurfaceID }) else {
            draggedCornerIndex = nil
            draggedSurfaceID = nil
            uncommittedCorners = nil
            return
        }
        let touch = recognizer.location(in: self)
        switch recognizer.state {
        case .began:
            let vertices = projectedCorners(of: surface)
            guard let nearest = vertices.enumerated().min(by: {
                hypot($0.element.x - touch.x, $0.element.y - touch.y)
                    < hypot($1.element.x - touch.x, $1.element.y - touch.y)
            }),
            hypot(nearest.element.x - touch.x, nearest.element.y - touch.y) < 46 else {
                draggedCornerIndex = nil
                return
            }
            draggedCornerIndex = nearest.offset
            draggedSurfaceID = selectedSurfaceID
            uncommittedCorners = vertices.map {
                SurfaceViewPoint(
                    x: Double($0.x / bounds.width),
                    y: Double($0.y / bounds.height)
                )
            }
        case .changed:
            guard draggedSurfaceID == selectedSurfaceID,
                  let draggedCornerIndex,
                  var next = uncommittedCorners,
                  next.count == 4 else { return }
            next[draggedCornerIndex] = SurfaceViewPoint(
                x: Double(max(0, min(bounds.width, touch.x)) / bounds.width),
                y: Double(max(0, min(bounds.height, touch.y)) / bounds.height)
            )
            guard SurfaceScreenPolygon(id: selectedSurfaceID, corners: next).isConvex else {
                return
            }
            uncommittedCorners = next
            updateContours()
        case .ended:
            if draggedSurfaceID == selectedSurfaceID, let edited = uncommittedCorners,
               SurfaceScreenPolygon(id: selectedSurfaceID, corners: edited).isConvex {
                correctedCornersByID[selectedSurfaceID] = edited
                onCornerAdjusted?(selectedSurfaceID, edited)
            }
            draggedCornerIndex = nil
            draggedSurfaceID = nil
            uncommittedCorners = nil
            updateContours()
        case .cancelled, .failed:
            draggedCornerIndex = nil
            draggedSurfaceID = nil
            uncommittedCorners = nil
            updateContours()
        default:
            break
        }
    }

}
