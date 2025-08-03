import Foundation
import SwiftData
import PDFKit
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI
@testable import PayslipMax

// MARK: - Mock PDF Text Extraction Service
class MockPDFTextExtractionService: PDFTextExtractionServiceProtocol {
    // MARK: - Properties
    
    var extractTextCallCount = 0
    var shouldSucceed = true
    var textToReturn = "Mock PDF content for testing purposes"
    
    // MARK: - Initialization
    
    init(shouldSucceed: Bool = true, textToReturn: String? = nil) {
        self.shouldSucceed = shouldSucceed
        if let text = textToReturn {
            self.textToReturn = text
        }
    }
    
    // MARK: - Methods
    
    func reset() {
        extractTextCallCount = 0
    }
    
    func extractText(from data: Data) throws -> String {
        extractTextCallCount += 1
        
        if !shouldSucceed {
            throw PDFProcessingError.textExtractionFailed
        }
        
        return textToReturn
    }
    
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
        extractTextCallCount += 1
        
        if !shouldSucceed {
            return nil
        }
        
        // Simulate callback if provided
        if let callback = callback {
            callback(textToReturn, 1, 1)
        }
        
        return textToReturn
    }
    
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        extractTextCallCount += 1
        
        if !shouldSucceed {
            return nil
        }
        
        return textToReturn
    }
    
    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        extractTextCallCount += 1
        
        if !shouldSucceed {
            return nil
        }
        
        return textToReturn
    }
    
    func currentMemoryUsage() -> UInt64 {
        return 1024 * 1024 // Return 1MB as mock memory usage
    }
}

// MARK: - Mock PDF Parsing Coordinator
class MockPDFParsingCoordinator: PDFParsingCoordinatorProtocol {
    // MARK: - Properties
    
    var extractFullTextCallCount = 0
    var parsePayslipCallCount = 0
    var parsePayslipUsingParserCallCount = 0
    var selectBestParserCallCount = 0
    var lastDocument: PDFDocument?
    var lastText: String?
    var lastParserName: String?
    var textToReturn = "Mock PDF text for testing purposes"
    var payslipToReturn: PayslipItem?
    var parserToReturn: PayslipParser?
    var shouldThrowError = false
    
    // MARK: - Initialization
    
    init(payslipToReturn: PayslipItem? = nil, parserToReturn: PayslipParser? = nil) {
        self.payslipToReturn = payslipToReturn
        self.parserToReturn = parserToReturn
        
        // Create default payslip if none provided
        if self.payslipToReturn == nil {
            self.payslipToReturn = PayslipItem(
                id: UUID(),
                timestamp: Date(),
                month: "January",
                year: 2023,
                credits: 10000.0,
                debits: 2000.0,
                dsop: 500.0,
                tax: 1000.0,
                name: "Mock User",
                accountNumber: "123456789",
                panNumber: "ABCDE1234F",
                pdfData: Data()
            )
        }
    }
    
    // MARK: - Methods
    
    func reset() {
        extractFullTextCallCount = 0
        parsePayslipCallCount = 0
        parsePayslipUsingParserCallCount = 0
        selectBestParserCallCount = 0
        lastDocument = nil
        lastText = nil
        lastParserName = nil
        shouldThrowError = false
    }
    
    func extractFullText(from document: PDFDocument) -> String? {
        extractFullTextCallCount += 1
        lastDocument = document
        return textToReturn
    }
    
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipItem? {
        parsePayslipCallCount += 1
        lastDocument = pdfDocument
        
        if shouldThrowError {
            throw MockError.processingFailed
        }
        return payslipToReturn
    }
    
    func parsePayslip(pdfDocument: PDFDocument, using parserName: String) async throws -> PayslipItem? {
        parsePayslipUsingParserCallCount += 1
        lastDocument = pdfDocument
        lastParserName = parserName
        
        if shouldThrowError {
            throw MockError.processingFailed
        }
        
        // Basic mock logic: return the standard payslip if the parser name is known, otherwise nil
        if parserName == parserToReturn?.name || parserName == "MockParser1" {
            return payslipToReturn
        } else {
            // Simulate parser not found or failure
            return nil
        }
    }
    
    func selectBestParser(for text: String) -> PayslipParser? {
        selectBestParserCallCount += 1
        lastText = text
        return parserToReturn
    }
    
    func getAvailableParsers() -> [PayslipParser] {
        // Return a mock list of parsers for testing
        if let parser = parserToReturn {
            return [parser]
        } else {
            return []
        }
    }
}

// MARK: - Mock Payslip Parser
class MockPayslipParser: PayslipParser {
    // MARK: - Properties
    
    // Internal enum for confidence levels, used only within this class
    private enum MockConfidence {
        case low
        case medium
        case high
        
        func toParsingConfidence() -> ParsingConfidence {
            switch self {
            case .low: return ParsingConfidence.low
            case .medium: return ParsingConfidence.medium
            case .high: return ParsingConfidence.high
            }
        }
        
        static func from(_ confidence: String) -> MockConfidence {
            switch confidence.lowercased() {
            case "low": return .low
            case "medium": return .medium
            case "high", _: return .high
            }
        }
    }
    
    var name: String = "MockParser"
    var parsePayslipCallCount = 0
    var evaluateConfidenceCallCount = 0
    var lastDocument: PDFDocument?
    var lastPayslipItem: PayslipItem?
    var confidenceToReturn = ParsingConfidence.high
    var payslipToReturn: PayslipItem?
    var shouldThrowError = false
    
    // MARK: - Initialization
    
    init(name: String = "MockParser", confidenceToReturn: ParsingConfidence = .high, payslipToReturn: PayslipItem? = nil) {
        self.name = name
        self.confidenceToReturn = confidenceToReturn
        self.payslipToReturn = payslipToReturn
        
        // Create default payslip if none provided
        if self.payslipToReturn == nil {
            self.payslipToReturn = PayslipItem(
                id: UUID(),
                timestamp: Date(),
                month: "January",
                year: 2023,
                credits: 10000.0,
                debits: 2000.0,
                dsop: 500.0,
                tax: 1000.0,
                name: "Mock User",
                accountNumber: "123456789",
                panNumber: "ABCDE1234F",
                pdfData: Data()
            )
        }
    }
    
    // MARK: - Methods
    
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipItem? {
        parsePayslipCallCount += 1
        lastDocument = pdfDocument
        
        if shouldThrowError {
            throw MockError.processingFailed
        }
        
        return payslipToReturn
    }
    
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence {
        evaluateConfidenceCallCount += 1
        lastPayslipItem = payslipItem
        return confidenceToReturn
    }
    
    func reset() {
        parsePayslipCallCount = 0
        evaluateConfidenceCallCount = 0
        lastDocument = nil
        lastPayslipItem = nil
        shouldThrowError = false
    }
} 