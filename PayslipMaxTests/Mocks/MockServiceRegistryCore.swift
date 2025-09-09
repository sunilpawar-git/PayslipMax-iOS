import Foundation
import PDFKit
@testable import PayslipMax

/// Central coordination for all mock services used in tests.
/// Provides centralized registry and reset functionality.
/// Follows SOLID principles with protocol-based design and dependency injection.
@MainActor
public class MockServiceRegistry {

    // MARK: - Singleton
    public static let shared = MockServiceRegistry()

    // MARK: - Mock Services

    /// Mock security service for authentication and encryption testing
    public lazy var securityService: SecurityServiceProtocol = MockSecurityService()

    /// Mock PDF service for document processing testing
    public lazy var pdfService: PDFServiceProtocol = MockPDFService()

    /// Mock PDF extractor for text extraction testing
    public lazy var pdfExtractor: PDFExtractorProtocol = MockPDFExtractor()

    /// Mock encryption service for general encryption testing
    public lazy var encryptionService: EncryptionServiceProtocol = MockEncryptionService()

    /// Mock payslip format detection service for format detection testing
    public lazy var payslipFormatDetectionService: PayslipFormatDetectionServiceProtocol = MockPayslipFormatDetectionService()

    /// Mock validation services for test data validation
    internal lazy var payslipValidator: PayslipValidationServiceProtocol = PayslipValidationService()
    internal lazy var pdfValidator: PDFValidationServiceProtocol = PDFValidationService()

    // MARK: - Initialization

    private init() {}

    // MARK: - Registry Management

    /// Resets all mock services to their default state
    /// Follows Single Responsibility Principle - only manages service lifecycle
    public func resetAllServices() {
        // Reset all services to new instances
        securityService = MockSecurityService()
        pdfService = MockPDFService()
        pdfExtractor = MockPDFExtractor()
        encryptionService = MockEncryptionService()
        payslipFormatDetectionService = MockPayslipFormatDetectionService()

        // Reset validation services
        payslipValidator = PayslipValidationService()
        pdfValidator = PDFValidationService()
    }

    /// Configures all services for failure testing
    /// Enables comprehensive error scenario testing
    public func configureAllForFailure() {
        // Configure each service to simulate failures
        if let mockSecurity = securityService as? MockSecurityService {
            mockSecurity.shouldFailAuth = true
        }

        if let mockPDF = pdfService as? MockPDFService {
            mockPDF.shouldFailProcessing = true
        }

        if let mockEncryption = encryptionService as? MockEncryptionService {
            mockEncryption.shouldFailEncryption = true
            mockEncryption.shouldFailDecryption = true
        }
    }

    /// Configures all services for success testing
    /// Ensures all services are configured for successful operations
    public func configureAllForSuccess() {
        // Ensure all services are configured for successful operations
        if let mockSecurity = securityService as? MockSecurityService {
            mockSecurity.shouldFailAuth = false
        }

        if let mockPDF = pdfService as? MockPDFService {
            mockPDF.shouldFailProcessing = false
        }

        if let mockEncryption = encryptionService as? MockEncryptionService {
            mockEncryption.shouldFailEncryption = false
            mockEncryption.shouldFailDecryption = false
        }
    }
}
