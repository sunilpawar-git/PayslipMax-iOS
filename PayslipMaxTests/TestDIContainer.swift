import Foundation
import PDFKit
@testable import PayslipMax

// A simplified DI container specifically for tests - using modular mock services

// Simple MockServiceRegistry to satisfy remaining references
@MainActor
class MockServiceRegistry {
    static let shared = MockServiceRegistry()

    var securityService: SecurityServiceProtocol = CoreMockSecurityService()
    var pdfService: PDFServiceProtocol = MockPDFService()
    var pdfExtractor: PDFExtractorProtocol = MockPDFExtractor()
    var payslipFormatDetectionService: PayslipFormatDetectionServiceProtocol = MockPayslipFormatDetectionService()
    var payslipValidationService: PayslipValidationServiceProtocol = MockPayslipValidationService()
    var pdfTextExtractionService: PDFTextExtractionServiceProtocol = MockPDFTextExtractionService()
    var payslipEncryptionService: PayslipEncryptionServiceProtocol = MockPayslipEncryptionService()
    var payslipProcessingPipeline: PayslipProcessingPipeline = MockPayslipProcessingPipeline()
    var pdfParsingCoordinator: PDFParsingCoordinatorProtocol = MockPDFParsingCoordinator()

    func resetAllServices() {
        // Reset mock services if needed
    }
}

@MainActor
class TestDIContainer: DIContainer {
    
    // Direct mock instantiation for test isolation
    
    // Override init to set useMocks to true
    override init(useMocks: Bool = true) {
        super.init(useMocks: true)
    }
    
    // Static helper methods for tests - create NEW instances with fresh state
    static func forTesting() -> TestDIContainer {
        // Reset all services before creating new container for clean state
        MockServiceRegistry.shared.resetAllServices()
        return TestDIContainer() // Create a new instance each time
    }
    
    static func resetToDefault() {
        Task { @MainActor in
            // Reset all mock services to their default state using the registry
            MockServiceRegistry.shared.resetAllServices()
            
            // Reset DIContainer shared state
            DIContainer.shared.useMocks = false
        }
    }
    
    // Override services to use direct mock instances for proper test isolation
    override var securityService: SecurityServiceProtocol {
        return CoreMockSecurityService()
    }

    override var dataService: DataServiceProtocol {
        // Create DataServiceImpl with the mock security service
        return DataServiceImpl(securityService: CoreMockSecurityService())
    }

    override var pdfService: PDFServiceProtocol {
        return MockPDFService()
    }

    override var pdfExtractor: PDFExtractorProtocol {
        return MockPDFExtractor()
    }
    
    // Override factory methods for view models
    override func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(securityService: CoreMockSecurityService())
    }

    override func makePayslipsViewModel() -> PayslipsViewModel {
        return PayslipsViewModel(dataService: dataService)
    }

    func makePayslipDetailViewModel(for testPayslip: PayslipItem) -> PayslipDetailViewModel {
        return PayslipDetailViewModel(payslip: testPayslip, securityService: CoreMockSecurityService())
    }
    
    override func makeInsightsCoordinator() -> InsightsCoordinator {
        return InsightsCoordinator(dataService: dataService)
    }
    
    override func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(securityService: CoreMockSecurityService(), dataService: dataService)
    }
    
    override func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            pdfHandler: makePDFProcessingHandler(),
            dataHandler: makePayslipDataHandler(),
            chartService: makeChartDataPreparationService(),
            passwordHandler: makePasswordProtectedPDFHandler(),
            errorHandler: makeErrorHandler(),
            navigationCoordinator: makeHomeNavigationCoordinator()
        )
    }
    
    override func makeHomeNavigationCoordinator() -> HomeNavigationCoordinator {
        return HomeNavigationCoordinator()
    }
    
    override func makePDFProcessingHandler() -> PDFProcessingHandler {
        return PDFProcessingHandler(pdfProcessingService: makePDFProcessingService())
    }
    
    override func makePayslipDataHandler() -> PayslipDataHandler {
        return PayslipDataHandler(dataService: dataService)
    }
    
    override func makeChartDataPreparationService() -> ChartDataPreparationService {
        return ChartDataPreparationService()
    }
    
    override func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler {
        return PasswordProtectedPDFHandler(pdfService: MockPDFService())
    }
    
    /// Creates a PDFProcessingService instance for testing
    override func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        return PDFProcessingService(
            pdfService: makePDFService(),
            pdfExtractor: makePDFExtractor(),
            parsingCoordinator: MockPDFParsingCoordinator(),
            formatDetectionService: makePayslipFormatDetectionService(),
            validationService: makePayslipValidationService(),
            textExtractionService: makePDFTextExtractionService()
        )
    }
    
    /// Creates a mock parsing coordinator for testing
    override func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol {
        return MockPDFParsingCoordinator()
    }
    
    /// Creates a PayslipFormatDetectionService instance for testing
    override func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return MockPayslipFormatDetectionService()
    }

    /// Creates a PDFValidationService for testing
    override func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        return MockPayslipValidationService()
    }

    /// Creates a PDFTextExtractionService instance for testing
    override func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol {
        return MockPDFTextExtractionService()
    }
    
    /// Creates a PayslipProcessorFactory instance for testing
    override func makePayslipProcessorFactory() -> PayslipProcessorFactory {
        return PayslipProcessorFactory(formatDetectionService: makePayslipFormatDetectionService())
    }
    
    override func makeSecurityViewModel() -> SecurityViewModel {
        return SecurityViewModel()
    }
    
    override func makeErrorHandler() -> ErrorHandler {
        return ErrorHandler()
    }
    
    /// Creates a PayslipEncryptionService for testing
    override func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol {
        return MockPayslipEncryptionService()
    }
    
    // Helper to create a sample payslip for testing
    func createSamplePayslip() -> PayslipItem {
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2023,
            credits: 5000,
            debits: 1000,
            dsop: 500,
            tax: 800,
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            pdfData: nil
        )
        return payslipItem
    }
    
    /// Makes a PayslipProcessingPipeline for testing
    override func makePayslipProcessingPipeline() -> PayslipProcessingPipeline {
        return MockPayslipProcessingPipeline()
    }
}

// MARK: - Mock Classes for TestDIContainer

// Note: Mock classes are defined in their respective test files to avoid conflicts

