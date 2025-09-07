import Foundation
@testable import PayslipMax

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

// MARK: - Legacy Mock Services (Commented for future implementation)
/*
These mock services are commented out as they require complex implementations
that should be addressed in future phases when the actual services are fully implemented.

Future implementation plan:
1. Implement actual service protocols first
2. Create corresponding mock implementations
3. Integrate with mock registry

/// Mock payslip encryption service for data security testing
public class MockPayslipEncryptionService: PayslipEncryptionServiceProtocol {
    public func encrypt(_ payslip: PayslipItem) throws -> PayslipItem { payslip }
    public func decrypt(_ payslip: PayslipItem) throws -> PayslipItem { payslip }
}

/// Mock PDF processing service for full pipeline testing
public class MockPDFProcessingService: PDFProcessingServiceProtocol {
    public func processPDF(_ data: Data) async throws -> PayslipItem {
        PayslipItem(
            id: UUID(), month: "Mock", year: 2024, organization: "Mock Org",
            employeeName: "Mock Employee", employeeId: "MOCK123", designation: "Mock Role",
            department: "Mock Dept", payPeriod: "Mock Period", grossPay: 50000, netPay: 40000,
            totalDeductions: 10000, earnings: [:], deductions: [:], personalDetails: [:],
            additionalInfo: [:], pdfData: Data(), createdAt: Date(), lastModified: Date(),
            isEncrypted: false, encryptionKey: nil, payslipFormat: .defense
        )
    }
}

/// Mock PDF text extraction service for text processing testing
public class MockPDFTextExtractionService: PDFTextExtractionServiceProtocol {
    public func extractText(from document: PDFDocument) async -> String { "Mock extracted text" }
    public func extractText(from data: Data) async -> String { "Mock extracted text" }
}

/// Mock PDF parsing coordinator for coordination testing
public class MockPDFParsingCoordinator: PDFParsingCoordinatorProtocol {
    public func parsePDF(_ document: PDFDocument) async throws -> PayslipItem {
        PayslipItem(
            id: UUID(), month: "Mock", year: 2024, organization: "Mock Org",
            employeeName: "Mock Employee", employeeId: "MOCK123", designation: "Mock Role",
            department: "Mock Dept", payPeriod: "Mock Period", grossPay: 50000, netPay: 40000,
            totalDeductions: 10000, earnings: [:], deductions: [:], personalDetails: [:],
            additionalInfo: [:], pdfData: Data(), createdAt: Date(), lastModified: Date(),
            isEncrypted: false, encryptionKey: nil, payslipFormat: .defense
        )
    }
}

/// Mock payslip processing pipeline for full processing testing
public class MockPayslipProcessingPipeline: PayslipProcessingPipeline {
    public func processPayslip(_ data: Data) async throws -> PayslipItem {
        PayslipItem(
            id: UUID(), month: "Mock", year: 2024, organization: "Mock Org",
            employeeName: "Mock Employee", employeeId: "MOCK123", designation: "Mock Role",
            department: "Mock Dept", payPeriod: "Mock Period", grossPay: 50000, netPay: 40000,
            totalDeductions: 10000, earnings: [:], deductions: [:], personalDetails: [:],
            additionalInfo: [:], pdfData: Data(), createdAt: Date(), lastModified: Date(),
            isEncrypted: false, encryptionKey: nil, payslipFormat: .defense
        )
    }
}

/// Mock payslip validation service for validation testing
public class MockPayslipValidationService: PayslipValidationServiceProtocol {
    public func validatePayslip(_ payslip: PayslipItem) async throws -> Bool { true }
    public func validateFields(_ fields: [String: Any]) -> ValidationResult {
        ValidationResult(isValid: true, errors: [])
    }
    public func getValidationRules() -> [String] { ["Rule1"] }
}

/// Mock text extraction service for text processing testing
public class MockTextExtractionService: TextExtractionServiceProtocol {
    public func extractText(from data: Data) async -> String { "Mock extracted text" }
}
*/
