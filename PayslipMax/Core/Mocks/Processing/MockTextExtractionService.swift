import Foundation
import PDFKit

/// Mock implementation of TextExtractionServiceProtocol for testing purposes.
final class MockTextExtractionService: TextExtractionServiceProtocol {
    
    // MARK: - Properties
    var mockText: String = "This is mock extracted text"
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Public Methods
    func reset() {
        mockText = "This is mock extracted text"
    }
    
    // MARK: - TextExtractionServiceProtocol Implementation
    func extractText(from pdfDocument: PDFDocument) -> String {
        return mockText
    }
    
    func extractText(from page: PDFPage) -> String {
        return mockText
    }
    
    func extractDetailedText(from pdfDocument: PDFDocument) -> String {
        return mockText + "\n[DETAILED]"
    }
    
    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument) {
        // No-op for mock
    }
    
    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool {
        return !mockText.isEmpty
    }
} 