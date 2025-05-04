import Foundation
import PDFKit
@testable import PayslipMax

// MARK: - Mock Text Extraction Service
class MockTextExtractionService: TextExtractionServiceProtocol {
    var mockText: String = "This is mock extracted text"
    
    // Track method calls for verification in tests
    var extractTextFromDocumentCallCount = 0
    var extractTextFromPageCallCount = 0
    var extractDetailedTextCallCount = 0
    var logTextExtractionDiagnosticsCallCount = 0
    var hasTextContentCallCount = 0
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        extractTextFromDocumentCallCount += 1
        return mockText
    }
    
    func extractText(from page: PDFPage) -> String {
        extractTextFromPageCallCount += 1
        return mockText
    }
    
    func extractDetailedText(from pdfDocument: PDFDocument) -> String {
        extractDetailedTextCallCount += 1
        return mockText + "\n[DETAILED]"
    }
    
    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument) {
        logTextExtractionDiagnosticsCallCount += 1
    }
    
    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool {
        hasTextContentCallCount += 1
        return !mockText.isEmpty
    }
    
    func reset() {
        mockText = "This is mock extracted text"
        extractTextFromDocumentCallCount = 0
        extractTextFromPageCallCount = 0
        extractDetailedTextCallCount = 0
        logTextExtractionDiagnosticsCallCount = 0
        hasTextContentCallCount = 0
    }
} 