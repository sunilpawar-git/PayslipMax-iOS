import Foundation
// IMPORTANT: DO NOT import PayslipMaxTests module here
// The mock services used should be from the same module to avoid import cycle

// A simplified DI container specifically for tests - implementation moved to PayslipMaxTests/TestHelpers
@MainActor
class TestDIContainer: DIContainer {
    // Singleton instance for tests
    static let testShared = TestDIContainer()
    
    // Mock services - made public for testing
    // Use mock services from the same module (PayslipMax/Core/DI/MockServices.swift)
    public let mockSecurityService = MockSecurityService()
    // Create a new MockDataService using our own implementation
    public let mockDataService: DataServiceProtocol = {
        let service = MockSecurityService()
        return DataServiceImpl(securityService: service)
    }()
    public let mockPDFService = MockPDFService()
    public let mockPDFExtractor = MockPDFExtractor()
    public let mockPayslipEncryptionService = MockPayslipEncryptionService()
    
    // Override init to set useMocks to true
    override init(useMocks: Bool = true) {
        super.init(useMocks: true)
    }
    
    // Static helper methods for tests
    static func forTesting() -> TestDIContainer {
        return testShared
    }
    
    static func resetToDefault() {
        // Reset the mock services to their default state
        testShared.mockSecurityService.reset()
        // mockDataService is now a DataServiceImpl, so we can't call reset() on it
        // testShared.mockDataService.reset()
        testShared.mockPDFService.reset()
        testShared.mockPDFExtractor.reset()
        testShared.mockPayslipEncryptionService.reset()
    }
    
    // Override services to use our mock instances
    override var securityService: SecurityServiceProtocol {
        return mockSecurityService
    }
    
    override var dataService: DataServiceProtocol {
        return mockDataService
    }
    
    override var pdfService: PDFServiceProtocol {
        return mockPDFService
    }
    
    override var pdfExtractor: PDFExtractorProtocol {
        return mockPDFExtractor
    }
    
    // Override factory methods for view models
    override func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(securityService: mockSecurityService)
    }
    
    override func makePayslipsViewModel() -> PayslipsViewModel {
        return PayslipsViewModel(dataService: mockDataService)
    }
    
    func makePayslipDetailViewModel(for testPayslip: PayslipItem) -> PayslipDetailViewModel {
        return PayslipDetailViewModel(payslip: testPayslip, securityService: mockSecurityService)
    }
    
    override func makeInsightsCoordinator() -> InsightsCoordinator {
        return InsightsCoordinator(dataService: mockDataService)
    }
    
    override func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(securityService: mockSecurityService, dataService: mockDataService)
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
        return PayslipDataHandler(dataService: mockDataService)
    }
    
    override func makeChartDataPreparationService() -> ChartDataPreparationService {
        return ChartDataPreparationService()
    }
    
    override func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler {
        return PasswordProtectedPDFHandler(pdfService: mockPDFService)
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
    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol {
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
        return mockPayslipEncryptionService
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