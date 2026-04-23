import Foundation
import CoreGraphics
@testable import PayslipMax

/// Mock implementation of StructuredOCRServiceProtocol for unit testing.
/// Uses @unchecked Sendable because mutable var stubs are set from test setUp only.
final class MockStructuredOCRService: StructuredOCRServiceProtocol, @unchecked Sendable {

    /// Pre-configured result to return from recognizeText calls
    var stubbedResult: StructuredOCRResult?
    /// Pre-configured detailed error to surface (overrides stubbedResult when set)
    var stubbedDetailedError: StructuredOCRError?

    /// Tracks the number of times recognizeText was called
    private(set) var recognizeCallCount = 0

    init(stubbedResult: StructuredOCRResult? = nil, stubbedDetailedError: StructuredOCRError? = nil) {
        self.stubbedResult = stubbedResult
        self.stubbedDetailedError = stubbedDetailedError
    }

    func recognizeText(from imageData: Data) async -> StructuredOCRResult? {
        recognizeCallCount += 1
        return stubbedResult
    }

    func recognizeText(from cgImage: CGImage) async -> StructuredOCRResult? {
        recognizeCallCount += 1
        return stubbedResult
    }

    func recognizeTextDetailed(from cgImage: CGImage) async -> Result<StructuredOCRResult, StructuredOCRError> {
        recognizeCallCount += 1
        if let error = stubbedDetailedError {
            return .failure(error)
        }
        if let result = stubbedResult {
            return .success(result)
        }
        return .failure(.noTextFound)
    }
}
