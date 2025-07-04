import Foundation
import PDFKit

/// Mock implementation of PDFServiceProtocol for testing purposes.
///
/// This mock service provides controllable behavior for testing PDF processing
/// functionality without requiring actual PDF operations. It includes configurable
/// success/failure modes and customizable return values.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockPDFService: PDFServiceProtocol {
    
    // MARK: - Properties
    
    /// Controls whether operations should fail
    var shouldFail = false
    
    /// The result data to return from extract operations
    var extractResult: [String: String] = [:]
    
    /// The result data to return from unlock operations
    var unlockResult: Data?
    
    /// Controls whether the service is considered initialized
    var isInitialized: Bool = false
    
    /// The validation result to return from validation operations
    var mockValidationResult = PayslipContentValidationResult(
        isValid: true,
        confidence: 1.0,
        detectedFields: [],
        missingRequiredFields: []
    )
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        shouldFail = false
        extractResult.removeAll()
        unlockResult = nil
        isInitialized = false
        mockValidationResult = PayslipContentValidationResult(
            isValid: true,
            confidence: 1.0,
            detectedFields: [],
            missingRequiredFields: []
        )
    }
    
    // MARK: - PDFServiceProtocol Implementation
    
    func initialize() async throws {
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func process(_ url: URL) async throws -> Data {
        if shouldFail {
            throw MockError.processingFailed
        }
        return Data()
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        if shouldFail {
            throw MockError.unlockFailed
        }
        if password != "correct" {
            throw MockError.incorrectPassword
        }
        return unlockResult ?? data
    }
    
    func extract(_ data: Data) -> [String: String] {
        if shouldFail {
            return [:]
        }
        return extractResult
    }
    
    func detectFormat(_ data: Data) -> PayslipFormat {
        return .pcda
    }
    
    func validateContent(_ data: Data) -> PayslipContentValidationResult {
        if shouldFail {
            return PayslipContentValidationResult(
                isValid: false,
                confidence: 0.0,
                detectedFields: [],
                missingRequiredFields: ["Mock validation failed"]
            )
        }
        return mockValidationResult
    }
    
    func validatePayslipData(_ data: [String: String]) -> PayslipContentValidationResult {
        if shouldFail {
            return PayslipContentValidationResult(
                isValid: false,
                confidence: 0.0,
                detectedFields: [],
                missingRequiredFields: ["Mock validation failed"]
            )
        }
        return mockValidationResult
    }
} 