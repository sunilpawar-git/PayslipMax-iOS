import Foundation
import XCTest
import PDFKit
@testable import Payslip_Max

// A simplified DI container specifically for tests
@MainActor
class TestDIContainer {
    // Singleton instance for tests
    static let shared = TestDIContainer()
    
    // Mock services - made public for testing
    public let securityService = MockSecurityService()
    public let dataService = MockDataService()
    public let pdfService = MockPDFService()
    public let pdfExtractor = MockPDFExtractor()
    
    // Factory methods for view models
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(securityService: securityService)
    }
    
    func makePayslipsViewModel() -> PayslipsViewModel {
        return PayslipsViewModel(dataService: dataService)
    }
    
    func makePayslipDetailViewModel(for testPayslip: TestPayslipItem) -> PayslipDetailViewModel {
        return PayslipDetailViewModel(payslip: testPayslip, securityService: securityService)
    }
    
    func makeInsightsViewModel() -> InsightsViewModel {
        return InsightsViewModel(dataService: dataService)
    }
    
    func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(securityService: securityService, dataService: dataService)
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            pdfProcessingService: makePDFProcessingService(),
            dataService: dataService
        )
    }
    
    func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        let abbreviationManager = AbbreviationManager()
        let parsingCoordinator = PDFParsingCoordinator(abbreviationManager: abbreviationManager)
        
        return PDFProcessingService(
            pdfService: pdfService,
            pdfExtractor: pdfExtractor,
            parsingCoordinator: parsingCoordinator
        )
    }
    
    func makeSecurityViewModel() -> SecurityViewModel {
        return SecurityViewModel()
    }
    
    // Helper to create a sample payslip for testing
    func createSamplePayslip() -> TestPayslipItem {
        return TestPayslipItem.sample()
    }
} 