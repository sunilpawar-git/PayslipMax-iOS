import Foundation
@testable import PayslipMax

// A simplified DI container specifically for tests - using modular mock services
@MainActor
class TestDIContainer: DIContainer {

    // Use MockServiceRegistry for proper test isolation - no local instances
    private let mockRegistry = MockServiceRegistry.shared

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

    // Override services to use registry instances for proper test isolation
    override var securityService: SecurityServiceProtocol {
        return mockRegistry.securityService
    }

    override var dataService: DataServiceProtocol {
        // Create DataServiceImpl with the mock security service
        do {
            return try DataServiceImpl(securityService: mockRegistry.securityService)
        } catch {
            fatalError("Failed to create DataServiceImpl: \(error)")
        }
    }

    override var pdfService: PDFServiceProtocol {
        return mockRegistry.pdfService
    }

    override var pdfExtractor: PDFExtractorProtocol {
        return mockRegistry.pdfExtractor
    }

    // Override factory methods for view models
    override func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(securityService: mockRegistry.securityService)
    }

    override func makePayslipsViewModel() -> PayslipsViewModel {
        return PayslipsViewModel(dataService: dataService)
    }

    func makePayslipDetailViewModel(for testPayslip: PayslipItem) -> PayslipDetailViewModel {
        return PayslipDetailViewModel(payslip: testPayslip, securityService: mockRegistry.securityService)
    }

    override func makeInsightsCoordinator() -> InsightsCoordinator {
        return InsightsCoordinator(dataService: dataService)
    }

    override func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(securityService: mockRegistry.securityService, dataService: dataService)
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
        return PasswordProtectedPDFHandler(pdfService: mockRegistry.pdfService)
    }

    // TODO: Re-enable after fixing dependent services
    // /// Creates a PDFProcessingService instance for testing
    // override func makePDFProcessingService() -> PDFProcessingServiceProtocol {
    //     return PDFProcessingService(
    //         pdfService: makePDFService(),
    //         pdfExtractor: makePDFExtractor(),
    //         parsingCoordinator: mockRegistry.pdfParsingCoordinator,
    //         formatDetectionService: makePayslipFormatDetectionService(),
    //         validationService: makePayslipValidationService(),
    //         textExtractionService: makePDFTextExtractionService()
    //     )
    // }

    // TODO: Re-enable after fixing PDFParsingCoordinator mock
    // /// Creates a mock parsing coordinator for testing
    // override func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol {
    //     return mockRegistry.pdfParsingCoordinator
    // }

    /// Creates a PayslipFormatDetectionService instance for testing
    override func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return mockRegistry.payslipFormatDetectionService
    }

    // TODO: Re-enable after fixing PayslipValidationService mock
    // /// Creates a PDFValidationService for testing
    // override func makePayslipValidationService() -> PayslipValidationServiceProtocol {
    //     return mockRegistry.payslipValidationService
    // }

    // TODO: Re-enable after fixing PDFTextExtractionService mock
    // /// Creates a PDFTextExtractionService instance for testing
    // override func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol {
    //     return mockRegistry.pdfTextExtractionService
    // }

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

    // TODO: Re-enable after fixing PayslipEncryptionService mock
    // /// Creates a PayslipEncryptionService for testing
    // override func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol {
    //     return mockRegistry.payslipEncryptionService
    // }

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

    /// TODO: Re-enable after fixing PayslipProcessingPipeline mock
    // /// Makes a PayslipProcessingPipeline for testing
    // override func makePayslipProcessingPipeline() -> PayslipProcessingPipeline {
    //     return mockRegistry.payslipProcessingPipeline
    // }

    /// Creates a TestDataValidator instance for testing with all required dependencies
    func makeTestDataValidator() -> TestDataValidatorProtocol {
        return TestDataValidator(
            payslipValidator: mockRegistry.payslipValidator,
            financialValidator: mockRegistry.financialValidator,
            pdfValidator: mockRegistry.pdfValidator,
            consistencyValidator: mockRegistry.consistencyValidator,
            panValidator: mockRegistry.panValidator,
            warningGenerator: mockRegistry.warningGenerator
        )
    }
}
