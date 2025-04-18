import Foundation

// A simplified DI container specifically for tests - implementation moved to PayslipMaxTests/TestHelpers
@MainActor
class TestDIContainer: DIContainer {
    // Singleton instance for tests
    static let testShared = TestDIContainer()
    
    // Mock services - made public for testing
    public let mockSecurityService = MockSecurityService()
    public let mockDataService = MockDataService()
    public let mockPDFService = MockPDFService()
    public let mockPDFExtractor = MockPDFExtractor()
    
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
    
    override func makeInsightsViewModel() -> InsightsViewModel {
        return InsightsViewModel(dataService: mockDataService)
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
    
    override func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        let abbreviationManager = AbbreviationManager()
        let parsingCoordinator = PDFParsingCoordinator(abbreviationManager: abbreviationManager)
        
        return PDFProcessingService(
            pdfService: mockPDFService,
            pdfExtractor: mockPDFExtractor,
            parsingCoordinator: parsingCoordinator
        )
    }
    
    override func makeSecurityViewModel() -> SecurityViewModel {
        return SecurityViewModel()
    }
    
    override func makeErrorHandler() -> ErrorHandler {
        return ErrorHandler()
    }
    
    // Helper to create a sample payslip for testing
    func createSamplePayslip() -> PayslipItem {
        return PayslipItem.sample()
    }
} 