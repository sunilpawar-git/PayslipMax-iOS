import Foundation
import PDFKit
@testable import Payslip_Max

class MockPDFExtractor: PDFExtractorProtocol {
    var shouldFailExtraction = false
    var extractTextCallCount = 0
    var extractImagesCallCount = 0
    var extractTablesCallCount = 0
    var extractPayslipDataCallCount = 0
    
    var extractTextCalled = false
    var extractTextCalledWithPDFDocument: PDFDocument?
    var extractTextResult = ""
    var extractImagesResult: [UIImage] = []
    var extractTablesResult: [[String]] = []
    var extractPayslipDataResult: PayslipItem?
    var availableParsers = ["MockParser"]

    // Implement PDFExtractorProtocol methods
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        extractPayslipDataCallCount += 1
        
        if shouldFailExtraction {
            return nil
        }
        
        return extractPayslipDataResult ?? PayslipItem(
            id: UUID(),
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "Test Name",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
    }
    
    func extractPayslipData(from text: String) -> PayslipItem? {
        extractPayslipDataCallCount += 1
        
        if shouldFailExtraction {
            return nil
        }
        
        return extractPayslipDataResult ?? PayslipItem(
            id: UUID(),
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "Test Name",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
    }
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        extractTextCalled = true
        extractTextCalledWithPDFDocument = pdfDocument
        return extractTextResult
    }
    
    func getAvailableParsers() -> [String] {
        return availableParsers
    }
    
    // Additional methods for extended functionality (not part of the protocol)
    func extractText(from page: PDFPage) -> String {
        extractTextCallCount += 1
        
        if shouldFailExtraction {
            return ""
        }
        
        return extractTextResult
    }
    
    func extractImages(from document: PDFDocument) -> [UIImage] {
        extractImagesCallCount += 1
        
        if shouldFailExtraction {
            return []
        }
        
        return extractImagesResult
    }
    
    func extractImages(from page: PDFPage) -> [UIImage] {
        extractImagesCallCount += 1
        
        if shouldFailExtraction {
            return []
        }
        
        return extractImagesResult
    }
    
    func extractTables(from document: PDFDocument) -> [[String]] {
        extractTablesCallCount += 1
        
        if shouldFailExtraction {
            return []
        }
        
        return extractTablesResult
    }
    
    func extractTables(from page: PDFPage) -> [[String]] {
        extractTablesCallCount += 1
        
        if shouldFailExtraction {
            return []
        }
        
        return extractTablesResult
    }
    
    func reset() {
        shouldFailExtraction = false
        extractTextCallCount = 0
        extractImagesCallCount = 0
        extractTablesCallCount = 0
        extractPayslipDataCallCount = 0
        extractTextCalled = false
        extractTextCalledWithPDFDocument = nil
        extractTextResult = ""
        extractImagesResult = []
        extractTablesResult = []
        extractPayslipDataResult = nil
    }
}

enum ExtractorError: Error {
    case textExtractionFailed
    case imageExtractionFailed
    case tableExtractionFailed
} 