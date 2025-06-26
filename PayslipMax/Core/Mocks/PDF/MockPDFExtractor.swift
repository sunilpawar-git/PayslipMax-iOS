import Foundation
import PDFKit

/// Mock implementation of PDFExtractorProtocol for testing purposes.
///
/// This mock service simulates PDF data extraction functionality without
/// requiring actual PDF processing. It provides controllable behavior
/// for testing extraction scenarios.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockPDFExtractor: PDFExtractorProtocol {
    
    // MARK: - Properties
    
    /// Controls whether operations should fail
    var shouldFail = false
    
    /// The payslip item to return from extraction operations
    var mockPayslipItem: PayslipItem?
    
    /// The text to return from text extraction operations
    var mockText = "This is mock extracted text"
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        shouldFail = false
        mockPayslipItem = nil
        mockText = "This is mock extracted text"
    }
    
    // MARK: - PDFExtractorProtocol Implementation
    
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        if shouldFail {
            return nil
        }
        if let item = mockPayslipItem {
            return item
        }
        return PayslipItemFactory.createSample() as? PayslipItem
    }
    
    func extractPayslipData(from text: String) -> PayslipItem? {
        if shouldFail {
            return nil
        }
        if let item = mockPayslipItem {
            return item
        }
        return PayslipItemFactory.createSample() as? PayslipItem
    }
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        if shouldFail {
            return ""
        }
        return mockText
    }
    
    func getAvailableParsers() -> [String] {
        return ["MockParser1", "MockParser2"]
    }
} 