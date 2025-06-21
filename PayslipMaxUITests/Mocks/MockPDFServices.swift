import Foundation
import PDFKit

// MARK: - PDF Service Protocols

/// Protocol for PDF processing services
protocol PDFServiceProtocol: ServiceProtocol {
    func processPDF(data: Data) async throws -> (any PayslipItemProtocol)?
    func processPDF(url: URL) async throws -> (any PayslipItemProtocol)?
    func unlockPDF(data: Data, password: String) async throws -> Data
}

/// Protocol for PDF extraction services
protocol PDFExtractorProtocol {
    func extractPayslipData(from pdfDocument: PDFDocument) -> (any PayslipItemProtocol)?
    func extractPayslipData(from text: String) -> (any PayslipItemProtocol)?
    func extractText(from pdfDocument: PDFDocument) -> String
    func getAvailableParsers() -> [String]
}

// MARK: - Mock PDF Service
class MockPDFService: PDFServiceProtocol {
    var pdfData: Data?
    var pdfText: String = """
    SALARY SLIP
    Name: Test User
    Account Number: 1234567890
    PAN: ABCDE1234F
    Month: January
    Year: 2025
    
    EARNINGS:
    Basic Pay: 3000.00
    DA: 1500.00
    MSP: 500.00
    Total: 5000.00
    
    DEDUCTIONS:
    DSOP: 500.00
    ITAX: 800.00
    AGIF: 200.00
    Total: 1500.00
    
    NET AMOUNT: 3500.00
    """
    
    var processPDFError: Error?
    var unlockPDFError: Error?
    var isInitialized: Bool = true
    
    func reset() {
        processPDFError = nil
        unlockPDFError = nil
    }
    
    func initialize() async throws {
        // No-op implementation for testing
    }
    
    func processPDF(data: Data) async throws -> (any PayslipItemProtocol)? {
        if let error = processPDFError {
            throw error
        }
        
        return TestPayslipItem.sample()
    }
    
    func processPDF(url: URL) async throws -> (any PayslipItemProtocol)? {
        if let error = processPDFError {
            throw error
        }
        
        return TestPayslipItem.sample()
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        if let error = unlockPDFError {
            throw error
        }
        
        return data
    }
}

// MARK: - Mock PDF Extractor
class MockPDFExtractor: PDFExtractorProtocol {
    var extractionError: Error?
    var extractTextResult: String = """
    SALARY SLIP
    Name: Test User
    Account Number: 1234567890
    PAN: ABCDE1234F
    Month: January
    Year: 2025
    
    EARNINGS:
    Basic Pay: 3000.00
    DA: 1500.00
    MSP: 500.00
    Total: 5000.00
    
    DEDUCTIONS:
    DSOP: 500.00
    ITAX: 800.00
    AGIF: 200.00
    Total: 1500.00
    
    NET AMOUNT: 3500.00
    """
    
    var availableParsers = ["PCDA Parser", "Generic Parser", "Custom Parser"]
    
    func reset() {
        extractionError = nil
    }
    
    func extractPayslipData(from pdfDocument: PDFDocument) -> (any PayslipItemProtocol)? {
        if extractionError != nil {
            return nil
        }
        
        return TestPayslipItem.sample()
    }
    
    func extractPayslipData(from text: String) -> (any PayslipItemProtocol)? {
        if extractionError != nil {
            return nil
        }
        
        return TestPayslipItem.sample()
    }
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        return extractTextResult
    }
    
    func getAvailableParsers() -> [String] {
        return availableParsers
    }
} 