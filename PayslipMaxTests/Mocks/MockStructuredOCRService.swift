import Foundation
import CoreGraphics
@testable import PayslipMax

/// Mock implementation of StructuredOCRServiceProtocol for unit testing.
/// Returns pre-configured results without invoking Apple Vision.
final class MockStructuredOCRService: StructuredOCRServiceProtocol, @unchecked Sendable {

    /// Pre-configured result to return from recognizeText calls
    var stubbedResult: StructuredOCRResult?

    /// Tracks the number of times recognizeText was called
    private(set) var recognizeCallCount = 0

    func recognizeText(from imageData: Data) async -> StructuredOCRResult? {
        recognizeCallCount += 1
        return stubbedResult
    }

    func recognizeText(from cgImage: CGImage) async -> StructuredOCRResult? {
        recognizeCallCount += 1
        return stubbedResult
    }
}
