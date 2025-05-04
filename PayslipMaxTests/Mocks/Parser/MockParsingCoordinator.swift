import Foundation
import PDFKit
@testable import PayslipMax

class MockParsingCoordinator: ParsingCoordinatorProtocol {
    var parseCallCount = 0
    var prioritizeCallCount = 0
    var extractCallCount = 0
    var parseAndExtractCallCount = 0
    
    var shouldFailParse = false
    var shouldFailExtract = false
    var shouldFailParseAndExtract = false
    
    var parsingResult: [ParsingDataType: Any] = [:]
    var prioritizedResult: [String: String] = [:]
    var extractionResult: [String: String] = [:]
    var parseAndExtractResult: PayslipItem?
    
    func parse(_ pdf: PDFDocument) async throws -> [ParsingDataType: Any] {
        parseCallCount += 1
        
        if shouldFailParse {
            throw MockError.processingFailed
        }
        
        return parsingResult
    }
    
    func prioritize(from parsed: [ParsingDataType: Any]) -> [String: String] {
        prioritizeCallCount += 1
        return prioritizedResult
    }
    
    func extract(from pdf: PDFDocument) async throws -> [String: String] {
        extractCallCount += 1
        
        if shouldFailExtract {
            throw MockError.extractionFailed
        }
        
        return extractionResult
    }
    
    func parseAndExtract(_ pdf: PDFDocument) async throws -> PayslipItem {
        parseAndExtractCallCount += 1
        
        if shouldFailParseAndExtract {
            throw MockError.processingFailed
        }
        
        if let result = parseAndExtractResult {
            return result
        }
        
        // Create default test payslip if no result configured
        let testPayslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2023,
            credits: 1000.0,
            debits: 200.0,
            dsop: 50.0,
            tax: 150.0,
            name: "Test User",
            accountNumber: "XXXX1234",
            panNumber: "AAAPL1234A",
            pdfData: nil
        )
        
        return testPayslip
    }
    
    // Helper for setting up returns
    func mockResults(parsing: [ParsingDataType: Any] = [:],
                    prioritized: [String: String] = [:],
                    extraction: [String: String] = [:],
                    completeParse: PayslipItem? = nil) {
        self.parsingResult = parsing
        self.prioritizedResult = prioritized
        self.extractionResult = extraction
        self.parseAndExtractResult = completeParse
    }
    
    // Reset all state
    func reset() {
        parseCallCount = 0
        prioritizeCallCount = 0
        extractCallCount = 0
        parseAndExtractCallCount = 0
        
        shouldFailParse = false
        shouldFailExtract = false
        shouldFailParseAndExtract = false
        
        parsingResult = [:]
        prioritizedResult = [:]
        extractionResult = [:]
        parseAndExtractResult = nil
    }
} 