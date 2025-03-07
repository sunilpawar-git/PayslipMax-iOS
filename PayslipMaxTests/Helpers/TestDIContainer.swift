import Foundation
import XCTest
import PDFKit
@testable import Payslip_Max

// A simplified DI container specifically for tests
// This avoids the issues with the main app's DI system
class TestDIContainer {
    // Singleton instance for tests
    static let shared = TestDIContainer()
    
    // Mock services
    let securityService = MockSecurityService()
    let dataService = MockDataService()
    let pdfService = MockPDFService()
    let pdfExtractor = MockPDFExtractor()
    
    // Factory methods for view models
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(securityService: securityService)
    }
    
    func makePayslipsViewModel() -> PayslipsViewModel {
        return PayslipsViewModel(dataService: dataService)
    }
    
    func makePayslipDetailViewModel(for testPayslip: TestPayslipItem) -> PayslipDetailViewModel {
        // TestPayslipItem already conforms to PayslipItemProtocol, so we can use it directly
        return PayslipDetailViewModel(payslip: testPayslip, securityService: securityService)
    }
    
    func makeInsightsViewModel() -> InsightsViewModel {
        return InsightsViewModel(dataService: dataService)
    }
    
    func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(securityService: securityService, dataService: dataService)
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        let pdfManager = PDFUploadManager()
        return HomeViewModel(pdfManager: pdfManager)
    }
    
    func makeSecurityViewModel() -> SecurityViewModel {
        return SecurityViewModel()
    }
    
    // Helper to create a sample payslip for testing
    func createSamplePayslip() -> TestPayslipItem {
        return TestPayslipItem.sample()
    }
}

// Mock implementation of PDFExtractorProtocol for testing
class MockPDFExtractor: PDFExtractorProtocol {
    var shouldFail = false
    var extractCount = 0
    var parseCount = 0
    
    func extractPayslipData(from document: PDFDocument) async throws -> any PayslipItemProtocol {
        extractCount += 1
        if shouldFail {
            throw PDFExtractionError.textExtractionFailed
        }
        return TestPayslipItem.sample()
    }
    
    func parsePayslipData(from text: String) throws -> any PayslipItemProtocol {
        parseCount += 1
        if shouldFail {
            throw PDFExtractionError.parsingFailed("Mock failure")
        }
        return TestPayslipItem.sample()
    }
} 