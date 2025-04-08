import Foundation
import PDFKit
@testable import Payslip_Max

// Define the protocol based on PDFParsingCoordinator functionality
// protocol PDFParsingCoordinatorProtocol {
//    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem?
//    func selectBestParser(for text: String) -> PayslipParser?
// }

class MockParsingCoordinator: PDFParsingCoordinatorProtocol {
    var shouldFailParsing = false
    var parseCallCount = 0
    var parsePayslipCallCount = 0
    var selectBestParserCallCount = 0
    var extractFullTextCallCount = 0
    var parsingResult: PayslipItem?
    var bestParserResult: PayslipParser?
    var extractedText: String?
    var availableParsers = ["MockParser"]

    // Implement PDFParsingCoordinatorProtocol methods
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem? {
        parsePayslipCallCount += 1
        
        if shouldFailParsing {
            return nil
        }
        
        return parsingResult ?? PayslipItem(
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
    
    func selectBestParser(for text: String) -> PayslipParser? {
        selectBestParserCallCount += 1
        return bestParserResult
    }
    
    // Implementation of the missing method required by PDFParsingCoordinatorProtocol
    func extractFullText(from document: PDFDocument) -> String? {
        extractFullTextCallCount += 1
        
        if shouldFailParsing {
            return nil
        }
        
        return extractedText ?? "This is mock extracted text from PDF document for testing purposes."
    }
    
    func parse(text: String) throws -> PayslipItem {
        parseCallCount += 1
        
        if shouldFailParsing {
            throw ParsingError.invalidFormat
        }
        
        if let result = parsingResult {
            return result
        }
        
        // Default implementation for tests
        return PayslipItem(
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
    
    func reset() {
        shouldFailParsing = false
        parseCallCount = 0
        parsePayslipCallCount = 0
        selectBestParserCallCount = 0
        extractFullTextCallCount = 0
        parsingResult = nil
        bestParserResult = nil
        extractedText = nil
    }
}

enum ParsingError: Error {
    case invalidFormat
} 