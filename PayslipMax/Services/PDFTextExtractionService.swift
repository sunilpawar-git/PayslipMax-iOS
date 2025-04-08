import Foundation
import PDFKit

/// Protocol for PDF text extraction service
protocol PDFTextExtractionServiceProtocol {
    /// Extracts text from a PDF
    /// - Parameter data: PDF data
    /// - Returns: Extracted text
    /// - Throws: Error if extraction fails
    func extractText(from data: Data) throws -> String
}

/// Service responsible for extracting text from PDF documents
class PDFTextExtractionService: PDFTextExtractionServiceProtocol {
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - PDFTextExtractionServiceProtocol
    
    func extractText(from data: Data) throws -> String {
        print("[PDFTextExtractionService] Extracting text from PDF data of size: \(data.count) bytes")
        
        // Create a PDF document
        guard let document = PDFDocument(data: data) else {
            print("[PDFTextExtractionService] Failed to create PDF document from data")
            throw PDFExtractionError.invalidPDFDocument
        }
        
        // Extract text from each page
        var extractedText = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i),
               let pageText = page.string {
                extractedText += pageText + "\n"
            }
        }
        
        // Validate extracted text
        guard !extractedText.isEmpty else {
            print("[PDFTextExtractionService] No text extracted from PDF")
            throw PDFExtractionError.noTextExtracted
        }
        
        print("[PDFTextExtractionService] Extracted \(extractedText.count) characters from PDF")
        return extractedText
    }
}

/// Error types for PDF extraction
enum PDFExtractionError: Error {
    case invalidPDFDocument
    case noTextExtracted
    
    var localizedDescription: String {
        switch self {
        case .invalidPDFDocument:
            return "The document is not a valid PDF."
        case .noTextExtracted:
            return "No text could be extracted from the PDF."
        }
    }
} 