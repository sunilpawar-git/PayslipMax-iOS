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
            pdfService: pdfService,
            pdfExtractor: pdfExtractor,
            dataService: dataService
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

// Mock implementation of PDFExtractorProtocol for testing
class MockPDFExtractor: PDFExtractorProtocol {
    var shouldFail = false
    var extractCount = 0
    var parseCount = 0
    
    func extractPayslipData(from document: PDFDocument) async throws -> any PayslipItemProtocol {
        extractCount += 1
        print("MockPDFExtractor: extractPayslipData called, count now: \(extractCount)")
        
        if shouldFail {
            throw MockPDFError.extractionFailed
        }
        
        // Return a test payslip with the expected values for the tests
        return TestPayslipItem(
            month: "April",
            year: 2023,
            credits: 5000.00,
            debits: 1000.00,
            dsop: 500.00,
            tax: 800.00,
            location: "New Delhi",
            name: "John Doe",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
    }
    
    func parsePayslipData(from text: String) throws -> any PayslipItemProtocol {
        parseCount += 1
        
        if shouldFail {
            throw MockPDFError.parsingFailed
        }
        
        // Return a test payslip with the expected values for the tests
        return TestPayslipItem(
            month: "April",
            year: 2023,
            credits: 5000.00,
            debits: 1000.00,
            dsop: 500.00,
            tax: 800.00,
            location: "New Delhi",
            name: "John Doe",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
    }
} 