import Foundation
import SwiftData
@testable import PayslipMax

// A simplified DI container specifically for tests - using modular mock services
@MainActor
class TestDIContainer {

    // Use MockServiceRegistry for proper test isolation - no local instances
    private let mockRegistry = MockServiceRegistry.shared
    // Optional ModelContext for integration tests
    private var testModelContext: ModelContext?

    // DIContainer reference for delegation
    private let diContainer = DIContainer.shared

    // Private init
    init() {
        self.diContainer.useMocks = true
    }

    // Method to set test model context
    func setTestModelContext(_ modelContext: ModelContext) {
        self.testModelContext = modelContext
    }

    // Static helper methods for tests - create NEW instances with fresh state
    static func forTesting() -> TestDIContainer {
        // Reset all services before creating new container for clean state
        MockServiceRegistry.shared.resetAllServices()
        return TestDIContainer() // Create a new instance each time
    }

    // Static helper for integration tests with specific ModelContext
    static func forIntegrationTesting(modelContext: ModelContext) -> TestDIContainer {
        // Reset all services before creating new container for clean state
        MockServiceRegistry.shared.resetAllServices()
        
        // Reset DIContainer shared state to clean up any previous references
        DIContainer.shared.useMocks = false
        
        let container = TestDIContainer()
        container.setTestModelContext(modelContext)
        return container
    }

    static func resetToDefault() {
        Task { @MainActor in
            // Reset all mock services to their default state using the registry
            MockServiceRegistry.shared.resetAllServices()

            // Reset DIContainer shared state
            DIContainer.shared.useMocks = false
        }
    }
    
    // Cleanup method to reset container state
    func cleanup() {
        // Reset the shared container state
        diContainer.useMocks = false
        
        // Clear test model context
        testModelContext = nil
    }

    // Services to use registry instances for proper test isolation
    var securityService: SecurityServiceProtocol {
        return mockRegistry.securityService
    }

    var dataService: DataServiceProtocol {
        // Create DataServiceImpl with the mock security service and test ModelContext if available
        do {
            if let modelContext = testModelContext {
                return DataServiceImpl(securityService: mockRegistry.securityService, modelContext: modelContext)
            } else {
                return try DataServiceImpl(securityService: mockRegistry.securityService)
            }
        } catch {
            fatalError("Failed to create DataServiceImpl: \(error)")
        }
    }

    var pdfService: PDFServiceProtocol {
        return mockRegistry.pdfService
    }

    var pdfExtractor: PDFExtractorProtocol {
        return mockRegistry.pdfExtractor
    }

    // Factory methods for view models
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(securityService: mockRegistry.securityService)
    }

    func makePayslipsViewModel() -> PayslipsViewModel {
        return PayslipsViewModel(dataService: dataService)
    }

    func makePayslipDetailViewModel(for testPayslip: PayslipItem) -> PayslipDetailViewModel {
        return PayslipDetailViewModel(payslip: testPayslip, securityService: mockRegistry.securityService)
    }

    func makeInsightsCoordinator() -> InsightsCoordinator {
        return InsightsCoordinator(dataService: dataService)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(securityService: mockRegistry.securityService, dataService: dataService)
    }

    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            pdfHandler: makePDFProcessingHandler(),
            dataHandler: makePayslipDataHandler(),
            chartService: makeChartDataPreparationService(),
            passwordHandler: makePasswordProtectedPDFHandler(),
            errorHandler: makeErrorHandler(),
            navigationCoordinator: makeHomeNavigationCoordinator()
        )
    }

    func makeHomeNavigationCoordinator() -> HomeNavigationCoordinator {
        return HomeNavigationCoordinator()
    }

    func makePDFProcessingHandler() -> PDFProcessingHandler {
        return PDFProcessingHandler(pdfProcessingService: makePDFProcessingService())
    }

    func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        // Delegate to the shared DI container for this service
        return diContainer.makePDFProcessingService()
    }

    func makePayslipDataHandler() -> PayslipDataHandler {
        return PayslipDataHandler(dataService: dataService)
    }

    func makeChartDataPreparationService() -> ChartDataPreparationService {
        return ChartDataPreparationService()
    }

    func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler {
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
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
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
    func makePayslipProcessorFactory() -> PayslipProcessorFactory {
        return PayslipProcessorFactory(formatDetectionService: makePayslipFormatDetectionService())
    }

    func makeSecurityViewModel() -> SecurityViewModel {
        return SecurityViewModel()
    }

    func makeErrorHandler() -> ErrorHandler {
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
            pdfValidator: mockRegistry.pdfValidator
        )
    }
}
