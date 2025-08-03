import Foundation
import PDFKit
@testable import PayslipMax

/// Mock implementation of PayslipPDFService for testing
@MainActor
class MockPayslipPDFService: PayslipPDFService {
    
    // MARK: - Mock State
    var shouldThrowError = false
    var mockError = AppError.message("Mock PDF Service Error")
    var mockPDFData = Data()
    var mockPDFURL: URL?
    
    // Track method calls
    var createFormattedPlaceholderPDFCallCount = 0
    var getPDFURLCallCount = 0
    
    override init(dataService: DataServiceProtocol? = nil,
                  validationService: PDFValidationServiceProtocol? = nil,
                  formattingService: PayslipPDFFormattingServiceProtocol? = nil,
                  urlService: PayslipPDFURLServiceProtocol? = nil) {
        // Initialize with mock services to avoid DIContainer dependencies
        super.init(
            dataService: dataService ?? MockDataService(),
            validationService: validationService ?? MockPDFValidationService(),
            formattingService: formattingService ?? MockPayslipPDFFormattingService(),
            urlService: urlService ?? MockPayslipPDFURLService()
        )
        
        // Set up default mock PDF data
        setupDefaultMockData()
    }
    
    private func setupDefaultMockData() {
        // Create a simple PDF header for testing
        let pdfHeader = Data([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34])  // %PDF-1.4
        let pdfContent = Data("Mock PDF Content".utf8)
        mockPDFData = pdfHeader + pdfContent
    }
    
    // Test helper methods to access the mocked data
    func getMockFormattedPDF(from payslipData: Models.PayslipData, payslip: AnyPayslip) -> Data {
        createFormattedPlaceholderPDFCallCount += 1
        return mockPDFData
    }
    
    func getMockPDFURL(for payslip: AnyPayslip) async throws -> URL? {
        getPDFURLCallCount += 1
        
        if shouldThrowError {
            throw mockError
        }
        
        return mockPDFURL
    }
    
    // MARK: - Test Helper Methods
    
    func reset() {
        shouldThrowError = false
        mockError = AppError.message("Mock PDF Service Error")
        createFormattedPlaceholderPDFCallCount = 0
        getPDFURLCallCount = 0
        mockPDFURL = nil
        setupDefaultMockData()
    }
    
    func setMockPDFData(_ data: Data) {
        mockPDFData = data
    }
    
    func setMockPDFURL(_ url: URL?) {
        mockPDFURL = url
    }
}

// MARK: - Supporting Mock Services

class MockPDFValidationService: PDFValidationServiceProtocol {
    func validatePDF(_ pdfDocument: PDFDocument) throws {
        // Mock implementation - does not throw for testing
    }
    
    func validatePayslipContent(_ pdfDocument: PDFDocument) -> PayslipValidationResult {
        return PayslipValidationResult(isValid: true, confidenceScore: 1.0, message: "Mock validation successful")
    }
    
    func isPDFValid(data: Data) -> Bool { 
        return true 
    }
    
    func checkForMilitaryPDFFormat(_ data: Data) -> Bool { 
        return true 
    }
}

class MockPayslipPDFFormattingService: PayslipPDFFormattingServiceProtocol {
    public func createFormattedPlaceholderPDF(from payslipData: Models.PayslipData, payslip: any PayslipProtocol) -> Data {
        let pdfHeader = Data([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34])  // %PDF-1.4
        let pdfContent = Data("Mock Formatted PDF Content".utf8)
        return pdfHeader + pdfContent
    }
}

class MockPayslipPDFURLService: PayslipPDFURLServiceProtocol {
    func getPDFURL(for payslip: any PayslipProtocol) async throws -> URL? {
        // Return a temporary mock URL for testing
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("mock_payslip.pdf")
    }
}