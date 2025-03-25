import Foundation
import UIKit
import PDFKit
@testable import Payslip_Max

class MockPDFExtractor: PDFExtractorProtocol {
    nonisolated(unsafe) var shouldFail = false
    nonisolated(unsafe) var extractPayslipDataFromDocumentCallCount = 0
    nonisolated(unsafe) var extractPayslipDataFromTextCallCount = 0
    nonisolated(unsafe) var extractTextCallCount = 0
    nonisolated(unsafe) var getAvailableParsersCallCount = 0
    
    // Legacy property for backward compatibility
    nonisolated(unsafe) var extractCount = 0
    
    nonisolated(unsafe) var extractPayslipDataResult: PayslipItem?
    nonisolated(unsafe) var parsePayslipDataFromTextResult: PayslipItem? // Added for tests
    nonisolated(unsafe) var extractTextResult: [String: String] = [:]
    nonisolated(unsafe) var availableParsers: [String] = ["Default", "Military", "PCDA"]
    
    // Add compatibility property referenced in tests
    nonisolated(unsafe) var resultToReturn: PayslipItem?
    
    nonisolated func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        extractPayslipDataFromDocumentCallCount += 1
        extractCount += 1 // Increment legacy counter
        if shouldFail {
            return nil
        }
        return resultToReturn ?? extractPayslipDataResult
    }
    
    nonisolated func extractPayslipData(from text: String) -> PayslipItem? {
        extractPayslipDataFromTextCallCount += 1
        extractCount += 1 // Increment legacy counter
        if shouldFail {
            return nil
        }
        return resultToReturn ?? extractPayslipDataResult
    }
    
    nonisolated func extractText(from pdfDocument: PDFDocument) -> String {
        extractTextCallCount += 1
        extractCount += 1 // Increment legacy counter
        if shouldFail {
            return ""
        }
        return extractTextResult.values.joined(separator: "\n")
    }
    
    nonisolated func getAvailableParsers() -> [String] {
        getAvailableParsersCallCount += 1
        return availableParsers
    }
    
    // Legacy method for backward compatibility
    nonisolated func parsePayslipDataFromText(_ textPages: [String: String]) -> PayslipItem? {
        // Convert dictionary to single string
        let text = textPages.values.joined(separator: "\n")
        extractPayslipDataFromTextCallCount += 1
        if shouldFail {
            return nil
        }
        return resultToReturn ?? parsePayslipDataFromTextResult ?? extractPayslipDataResult
    }
    
    // Reset the mock to default state
    nonisolated func reset() {
        shouldFail = false
        extractPayslipDataFromDocumentCallCount = 0
        extractPayslipDataFromTextCallCount = 0
        extractTextCallCount = 0
        getAvailableParsersCallCount = 0
        extractCount = 0
        extractPayslipDataResult = nil
        extractTextResult = [:]
        parsePayslipDataFromTextResult = nil
        resultToReturn = nil
    }
} 