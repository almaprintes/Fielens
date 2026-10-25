import Combine
import CoreMotion
import Foundation

enum LevelSensorStatus: Equatable {
    case idle
    case waiting
    case active
    case invalidPose
    case unavailable
}

/// Experimental level sampled at 20 Hz on a background operation queue.
/// No raw motion data, location or sensor samples are stored or sent anywhere.
@MainActor
final class LevelMotionModel: ObservableObject {
    @Published private(set) var status: LevelSensorStatus = .idle
    @Published private(set) var reading: LevelReading?

    private let manager = CMMotionManager()
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.almaprintes.fielens.motion"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private var isActive = false
    private var generation = 0
    private var filteredGravity: (x: Double, y: Double, z: Double)?

    func start() {
        guard !isActive else { return }
        guard manager.isDeviceMotionAvailable else {
            status = .unavailable
            reading = nil
            return
        }

        generation += 1
        let currentGeneration = generation
        isActive = true
        reading = nil
        filteredGravity = nil
        status = .waiting
        manager.deviceMotionUpdateInterval = 1.0 / 20.0

        manager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, error in
            guard error == nil, let motion else { return }
            let x = motion.gravity.x
            let y = motion.gravity.y
            let z = motion.gravity.z

            Task { @MainActor [weak self] in
                guard let self, self.isActive, self.generation == currentGeneration else {
                    return
                }
                self.accept(gravityX: x, gravityY: y, gravityZ: z)
            }
        }
    }

    func stop() {
        guard isActive else { return }
        isActive = false
        generation += 1
        manager.stopDeviceMotionUpdates()
        filteredGravity = nil
        reading = nil
        status = .idle
    }

    private func accept(gravityX x: Double, gravityY y: Double, gravityZ z: Double) {
        // Never show a stale green "level" while flipped or held upright.
        guard LevelMath.reading(gravityX: x, gravityY: y, gravityZ: z) != nil else {
            filteredGravity = nil
            reading = nil
            status = .invalidPose
            return
        }

        // Mild low-pass filtering reduces a visibly trembling indicator.
        // Filter resets after every interruption and invalid device pose.
        let alpha = 0.25
        if let old = filteredGravity {
            filteredGravity = (
                x: old.x + alpha * (x - old.x),
                y: old.y + alpha * (y - old.y),
                z: old.z + alpha * (z - old.z)
            )
        } else {
            filteredGravity = (x: x, y: y, z: z)
        }

        guard let filteredGravity,
              let latest = LevelMath.reading(
                gravityX: filteredGravity.x,
                gravityY: filteredGravity.y,
                gravityZ: filteredGravity.z
              ) else {
            reading = nil
            status = .invalidPose
            return
        }
        reading = latest
        status = .active
    }
}
