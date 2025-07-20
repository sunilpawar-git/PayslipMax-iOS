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
    public let mockSecurityService = CoreMockSecurityService()
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
        testShared.mockNavigationCoordinator.reset()
    }
    
    // MARK: - Service Property Overrides (correct return types)
    
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
    
    // MARK: - Factory Method Overrides (correct return types)
    
    override func makePDFProcessingHandler() -> PDFProcessingHandler {
        return mockPDFHandler
    }
    
    override func makePayslipDataHandler() -> PayslipDataHandler {
        return MockPayslipDataHandler()
    }
    
    override func makeChartDataPreparationService() -> ChartDataPreparationService {
        return mockChartService
    }
    
    override func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler {
        return mockPasswordHandler
    }
    
    override func makeErrorHandler() -> ErrorHandler {
        return mockErrorHandler
    }
    
    override func makeHomeNavigationCoordinator() -> HomeNavigationCoordinator {
        return mockNavigationCoordinator
    }
    
    // MARK: - Service Resolution Override
    
    override func resolve<T>(_ type: T.Type) -> T? {
        switch type {
        case is EncryptionServiceProtocol.Type:
            // Return the test's mock encryption service
            if let mockEncryptionService = MockEncryptionService() as? T {
                return mockEncryptionService
            }
            return super.resolve(type)
        default:
            return super.resolve(type)
        }
    }
    
    // MARK: - ViewModel Factory Method Overrides
    
    override func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(securityService: mockSecurityService)
    }
    
    override func makePayslipsViewModel() -> PayslipsViewModel {
        return PayslipsViewModel(dataService: mockDataService)
    }
    
    override func makeInsightsCoordinator() -> InsightsCoordinator {
        return InsightsCoordinator(dataService: mockDataService)
    }
    
    override func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(securityService: mockSecurityService, dataService: mockDataService)
    }
    
    override func makeSecurityViewModel() -> SecurityViewModel {
        return SecurityViewModel()
    }
    
    override func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            pdfHandler: mockPDFHandler,
            dataHandler: MockPayslipDataHandler(),
            chartService: mockChartService,
            passwordHandler: mockPasswordHandler,
            errorHandler: mockErrorHandler,
            navigationCoordinator: mockNavigationCoordinator
        )
    }
    
    // MARK: - Test Helper Methods (non-override)
    
    func makePayslipDetailViewModel(for testPayslip: TestPayslipItem) -> PayslipDetailViewModel {
        return PayslipDetailViewModel(payslip: testPayslip, securityService: mockSecurityService)
    }
    
    func createSamplePayslip() -> TestPayslipItem {
        return TestPayslipItem.sample()
    }
} 