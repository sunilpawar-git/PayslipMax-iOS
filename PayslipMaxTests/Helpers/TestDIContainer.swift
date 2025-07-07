import Foundation
import XCTest
import PDFKit
@testable import PayslipMax

// A simplified DI container specifically for tests
@MainActor
class TestDIContainer: DIContainer {
    // Singleton instance for tests
    static let testShared = TestDIContainer()
    
    // Mock services - made public for testing
    public let mockSecurityService = MockSecurityService()
    public let mockDataService = MockDataService()
    public let mockPDFService = MockPDFService()
    public let mockPDFExtractor = MockPDFExtractor()
    public let mockPDFHandler = MockPDFProcessingHandler()
    public let mockChartService = MockChartDataPreparationService()
    public let mockPasswordHandler = MockPasswordProtectedPDFHandler()
    public let mockErrorHandler = MockErrorHandler()
    public let mockNavigationCoordinator = MockHomeNavigationCoordinator()
    
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
        testShared.mockDataService.reset()
        testShared.mockPDFService.reset()
        testShared.mockPDFExtractor.reset()
        testShared.mockPDFHandler.reset()
        testShared.mockChartService.reset()
        testShared.mockPasswordHandler.reset()
        testShared.mockErrorHandler.reset()
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
    
    func makePayslipDetailViewModel(for testPayslip: TestPayslipItem) -> PayslipDetailViewModel {
        return PayslipDetailViewModel(payslip: testPayslip, securityService: mockSecurityService)
    }
    
    override func makeInsightsCoordinator() -> InsightsCoordinator {
        return InsightsCoordinator(dataService: mockDataService)
    }
    
    override func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(securityService: mockSecurityService, dataService: mockDataService)
    }
    
    func makePDFProcessingHandler() -> PDFProcessingHandler {
        return mockPDFHandler
    }
    
    func makePayslipDataHandler() -> PayslipDataHandler {
        return PayslipDataHandler(dataService: mockDataService)
    }
    
    func makeChartDataPreparationService() -> ChartDataPreparationService {
        return mockChartService
    }
    
    func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler {
        return mockPasswordHandler
    }
    
    func makeErrorHandler() -> ErrorHandler {
        return mockErrorHandler
    }
    
    func makeHomeNavigationCoordinator() -> HomeNavigationCoordinator {
        return mockNavigationCoordinator
    }
    
    override func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            pdfHandler: mockPDFHandler,
            dataHandler: makePayslipDataHandler(),
            chartService: mockChartService,
            passwordHandler: mockPasswordHandler,
            errorHandler: mockErrorHandler,
            navigationCoordinator: mockNavigationCoordinator
        )
    }
    
    override func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        let abbreviationManager = AbbreviationManager()
        let parsingCoordinator = PDFParsingOrchestrator(abbreviationManager: abbreviationManager)
        
        return PDFProcessingService(
            pdfService: mockPDFService,
            pdfExtractor: mockPDFExtractor,
            parsingCoordinator: parsingCoordinator,
            formatDetectionService: makePayslipFormatDetectionService(),
            validationService: makePayslipValidationService(),
            textExtractionService: makePDFTextExtractionService()
        )
    }
    
    override func makeSecurityViewModel() -> SecurityViewModel {
        return SecurityViewModel()
    }
    
    // Helper to create a sample payslip for testing
    func createSamplePayslip() -> TestPayslipItem {
        return TestPayslipItem.sample()
    }
} 