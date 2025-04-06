import Foundation
import PDFKit

/// Protocol for text extraction from PDF documents
protocol TextExtractionServiceProtocol {
    /// Extracts text from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from pdfDocument: PDFDocument) -> String
    
    /// Extracts text from a specific page of a PDF document
    /// - Parameters:
    ///   - page: The PDF page to extract text from
    /// - Returns: The extracted text
    func extractText(from page: PDFPage) -> String
    
    /// Extracts text from all pages of a PDF document with detailed logging
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractDetailedText(from pdfDocument: PDFDocument) -> String
    
    /// Logging text extraction diagnostic information
    /// - Parameter pdfDocument: The PDF document to diagnose
    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument)
    
    /// Checks if a PDF document is valid and contains text
    /// - Parameter pdfDocument: The PDF document to validate
    /// - Returns: True if the document is valid and has text content
    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool
} 