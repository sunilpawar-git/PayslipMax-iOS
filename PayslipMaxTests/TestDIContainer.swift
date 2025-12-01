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
        // Remove all NotificationCenter observers for any services that might have them
        NotificationCenter.default.removeObserver(mockRegistry)

        // Reset the shared container state
        diContainer.useMocks = false

        // Clear test model context
        testModelContext = nil

        // Force reset of all mock services to break any retain cycles
        mockRegistry.resetAllServices()

        // Clear any cached services in DIContainer
        DIContainer.shared.clearAllCaches()
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
        return PayslipsViewModel(repository: MockSendablePayslipRepository())
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
        // Use mock service for testing
        return mockRegistry.pdfProcessingService
    }

    func makePayslipDataHandler() -> PayslipDataHandler {
        return PayslipDataHandler(repository: MockSendablePayslipRepository(), dataService: dataService)
    }

    func makeChartDataPreparationService() -> ChartDataPreparationService {
        return ChartDataPreparationService()
    }

    func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler {
        return PasswordProtectedPDFHandler(pdfService: mockRegistry.pdfService)
    }





    /// Creates a PayslipFormatDetectionService instance for testing
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return mockRegistry.payslipFormatDetectionService
    }





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



    /// Creates a TestDataValidator instance for testing with all required dependencies
    func makeTestDataValidator() -> TestDataValidatorProtocol {
        return TestDataValidator(
            payslipValidator: mockRegistry.payslipValidator,
            pdfValidator: mockRegistry.pdfValidator
        )
    }
}
