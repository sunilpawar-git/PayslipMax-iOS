import Foundation
import UIKit
import PDFKit
@testable import Payslip_Max

class MockPDFExtractor: PDFExtractorProtocol {
    var shouldFail = false
    var extractPayslipDataFromDocumentCallCount = 0
    var extractPayslipDataFromTextCallCount = 0
    var extractTextCallCount = 0
    var getAvailableParsersCallCount = 0
    
    // Legacy property for backward compatibility
    var extractCount = 0
    
    var extractPayslipDataResult: PayslipItem?
    var extractTextResult: String = ""
    var availableParsers: [String] = ["Default", "Military", "PCDA"]
    
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        extractPayslipDataFromDocumentCallCount += 1
        extractCount += 1 // Increment legacy counter
        if shouldFail {
            return nil
        }
        return extractPayslipDataResult
    }
    
    func extractPayslipData(from text: String) -> PayslipItem? {
        extractPayslipDataFromTextCallCount += 1
        extractCount += 1 // Increment legacy counter
        if shouldFail {
            return nil
        }
        return extractPayslipDataResult
    }
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        extractTextCallCount += 1
        extractCount += 1 // Increment legacy counter
        if shouldFail {
            return ""
        }
        return extractTextResult
    }
    
    func getAvailableParsers() -> [String] {
        getAvailableParsersCallCount += 1
        return availableParsers
    }
    
    // Legacy method for backward compatibility
    func parsePayslipDataFromText(_ textPages: [String: String]) -> PayslipItem? {
        // Convert dictionary to single string
        let text = textPages.values.joined(separator: "\n")
        return extractPayslipData(from: text)
    }
} 