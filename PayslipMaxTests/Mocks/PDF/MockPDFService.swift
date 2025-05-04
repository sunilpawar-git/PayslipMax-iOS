import Foundation
import PDFKit
@testable import PayslipMax

// MARK: - Mock PDF Service
class MockPDFService: PDFServiceProtocol {
    var shouldFail = false
    var extractResult: [String: String] = [:]
    var unlockResult: Data?
    var isInitialized: Bool = false
    
    // Track method calls for verification in tests
    var extractCallCount = 0
    var unlockCallCount = 0
    var processCallCount = 0
    var initializeCallCount = 0
    var detectFormatCallCount = 0
    var validateContentCallCount = 0
    var validationCallCount = 0
    var mockValidationResult = PayslipContentValidationResult(
        isValid: true,
        confidence: 1.0,
        detectedFields: [],
        missingRequiredFields: []
    )
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func process(_ url: URL) async throws -> Data {
        processCallCount += 1
        if shouldFail {
            throw MockError.processingFailed
        }
        return Data()
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        unlockCallCount += 1
        if shouldFail {
            throw MockError.unlockFailed
        }
        if password != "correct" {
            throw MockError.incorrectPassword
        }
        if let result = unlockResult {
            return result
        }
        return data
    }
    
    func extract(_ data: Data) -> [String: String] {
        extractCallCount += 1
        if shouldFail {
            return [:]
        }
        return extractResult
    }
    
    func detectFormat(_ data: Data) -> PayslipFormat {
        detectFormatCallCount += 1
        return .pcda
    }
    
    func validateContent(_ data: Data) -> PayslipContentValidationResult {
        validateContentCallCount += 1
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
        validationCallCount += 1
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
    
    func reset() {
        shouldFail = false
        extractResult.removeAll()
        unlockResult = nil
        isInitialized = false
        extractCallCount = 0
        unlockCallCount = 0
        processCallCount = 0
        initializeCallCount = 0
        detectFormatCallCount = 0
        validateContentCallCount = 0
        validationCallCount = 0
        mockValidationResult = PayslipContentValidationResult(
            isValid: true,
            confidence: 1.0,
            detectedFields: [],
            missingRequiredFields: []
        )
    }
} 