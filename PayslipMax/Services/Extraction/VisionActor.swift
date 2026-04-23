import Foundation
import Vision

/// Actor that serialises all VNImageRequestHandler calls on a single task.
/// Eliminates the need for @unchecked Sendable on OCR service classes.
actor VisionActor {

    static let shared = VisionActor()

    /// Performs the supplied Vision requests on the given CGImage.
    /// Returns the resulting observations, or an empty array on error.
    func perform(
        _ requests: [VNRequest],
        on cgImage: CGImage
    ) throws {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform(requests)
    }
}
