import Foundation

/// Central registry for all mock services used in testing.
///
/// This registry provides a centralized way to access and manage all mock services
/// across the PayslipMax testing infrastructure. It ensures consistent service
/// initialization and provides convenient reset functionality for test isolation.
///
/// - Note: This is exclusively for testing and should never be used in production code.
@MainActor
final class MockServiceRegistry {
    
    // MARK: - Singleton
    
    /// Shared instance of the mock service registry
    static let shared = MockServiceRegistry()
    
    // MARK: - Mock Services
    
    /// Mock security service instance
    lazy var securityService = MockSecurityService()
    
    /// Mock PDF service instance
    lazy var pdfService = MockPDFService()
    
    /// Mock PDF processing service instance
    lazy var pdfProcessingService = MockPDFProcessingService()
    
    /// Mock PDF extractor instance
    lazy var pdfExtractor = MockPDFExtractor()
    
    /// Mock PDF text extraction service instance
    lazy var pdfTextExtractionService = MockPDFTextExtractionService()
    
    /// Mock PDF parsing coordinator instance
    lazy var pdfParsingCoordinator = MockPDFParsingCoordinator()
    
    /// Mock payslip processing pipeline instance
    lazy var payslipProcessingPipeline = MockPayslipProcessingPipeline()
    
    /// Mock payslip validation service instance
    lazy var payslipValidationService = MockPayslipValidationService()
    
    /// Mock payslip format detection service instance
    lazy var payslipFormatDetectionService = MockPayslipFormatDetectionService()
    
    /// Mock text extraction service instance
    lazy var textExtractionService = MockTextExtractionService()
    
    /// Mock payslip encryption service instance
    lazy var payslipEncryptionService = MockPayslipEncryptionService()
    
    /// Mock encryption service instance
    lazy var encryptionService = MockEncryptionService()
    
    /// Fallback payslip encryption service instance
    lazy var fallbackPayslipEncryptionService = FallbackPayslipEncryptionService(error: MockError.encryptionFailed)
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Resets all mock services to their default state.
    ///
    /// This method should be called between tests to ensure test isolation
    /// and prevent state leakage between test cases.
    func resetAllServices() {
        securityService.reset()
        pdfService.reset()
        pdfProcessingService.reset()
        pdfExtractor.reset()
        pdfTextExtractionService.reset()
        pdfParsingCoordinator.reset()
        payslipProcessingPipeline.reset()
        payslipValidationService.reset()
        payslipFormatDetectionService.reset()
        textExtractionService.reset()
        payslipEncryptionService.reset()
        encryptionService.reset()
    }
    
    /// Configures all services for success scenarios.
    ///
    /// Sets all mock services to return successful results, useful for
    /// testing happy path scenarios.
    func configureForSuccess() {
        resetAllServices()
        // Services are already configured for success by default
    }
    
    /// Configures all services for failure scenarios.
    ///
    /// Sets all mock services to return failure results, useful for
    /// testing error handling and edge cases.
    func configureForFailure() {
        resetAllServices()
        
        securityService.shouldFail = true
        pdfService.shouldFail = true
        pdfProcessingService.shouldFail = true
        pdfExtractor.shouldFail = true
        pdfTextExtractionService.shouldSucceed = false
        pdfParsingCoordinator.shouldThrowError = true
        payslipProcessingPipeline.shouldValidateSuccessfully = false
        payslipValidationService.structureIsValid = false
        payslipEncryptionService.shouldFailEncryption = true
        encryptionService.shouldFailEncryption = true
    }
} 