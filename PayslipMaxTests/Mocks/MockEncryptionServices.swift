import Foundation
import UIKit
@testable import PayslipMax

/// Mock PDF processing service for full pipeline testing
public class MockPDFProcessingService: PDFProcessingServiceProtocol {
    public var shouldFailProcessing = false
    public var isInitialized: Bool = true

    public func initialize() async throws {
        // Mock initialization - always succeeds
    }

    public func processPDF(from url: URL) async -> Result<Data, PDFProcessingError> {
        if shouldFailProcessing {
            return .failure(.processingFailed)
        }

        return .success(Data())
    }

    public func processPDFData(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        if shouldFailProcessing {
            return .failure(.processingFailed)
        }

        return .success(PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "Mock",
            year: 2024,
            credits: 50000,
            debits: 10000,
            dsop: 2500,
            tax: 7500,
            name: "Mock Employee",
            accountNumber: "MOCK123",
            panNumber: "ABCDE1234F"
        ))
    }

    public func isPasswordProtected(_ data: Data) -> Bool {
        return false
    }

    public func unlockPDF(_ data: Data, password: String) async -> Result<Data, PDFProcessingError> {
        return .success(data)
    }

    public func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError> {
        if shouldFailProcessing {
            return .failure(.processingFailed)
        }

        return .success(PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "Mock",
            year: 2024,
            credits: 50000,
            debits: 10000,
            dsop: 2500,
            tax: 7500,
            name: "Mock Employee",
            accountNumber: "MOCK123",
            panNumber: "ABCDE1234F"
        ))
    }

    public func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        return .defense
    }

    public func updateUserHint(_ hint: PayslipUserHint) { }

    public func validatePayslipContent(_ data: Data) -> PayslipContentValidationResult {
        return PayslipContentValidationResult(
            isValid: !shouldFailProcessing,
            confidence: shouldFailProcessing ? 0.0 : 0.8,
            detectedFields: ["name", "accountNumber", "credits", "debits"],
            missingRequiredFields: []
        )
    }
}

/// Mock encryption service for testing
/// Implements EncryptionServiceProtocol with configurable failure modes
/// Follows SOLID principles with single responsibility for encryption mocking
public class MockEncryptionService: EncryptionServiceProtocol {
    public var shouldFailEncryption = false
    public var shouldFailDecryption = false
    public var encryptionCount = 0
    public var decryptionCount = 0

    public func encrypt(_ data: Data) throws -> Data {
        encryptionCount += 1
        if shouldFailEncryption { throw MockError.encryptionFailed }
        return data
    }

    public func decrypt(_ data: Data) throws -> Data {
        decryptionCount += 1
        if shouldFailDecryption { throw MockError.encryptionFailed }
        return data
    }
}

