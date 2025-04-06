import Foundation
import PDFKit

/// Service for extracting text from PDF documents
class TextExtractionService: TextExtractionServiceProtocol {
    // MARK: - Public Methods
    
    /// Extracts text from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from pdfDocument: PDFDocument) -> String {
        return pdfDocument.string ?? ""
    }
    
    /// Extracts text from a specific page of a PDF document
    /// - Parameters:
    ///   - page: The PDF page to extract text from
    /// - Returns: The extracted text
    func extractText(from page: PDFPage) -> String {
        return page.string ?? ""
    }
    
    /// Extracts text from all pages of a PDF document with detailed logging
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractDetailedText(from pdfDocument: PDFDocument) -> String {
        var extractedText = ""
        
        print("TextExtractionService: PDF has \(pdfDocument.pageCount) pages")
        
        // Extract text from each page
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                let pageRect = page.bounds(for: .mediaBox)
                let pageSize = pageRect.size
                print("TextExtractionService: Page \(i+1) size: \(pageSize.width) x \(pageSize.height)")
                print("TextExtractionService: Page \(i+1) rotation: \(page.rotation)")
                
                // Extract text from page
                if let text = page.string, !text.isEmpty {
                    print("TextExtractionService: Page \(i+1) has \(text.count) characters of text")
                    extractedText += text + "\n\n"
                } else {
                    print("TextExtractionService: Page \(i+1) has no text content, may be image-only")
                }
            }
        }
        
        return extractedText
    }
    
    /// Logging text extraction diagnostic information
    /// - Parameter pdfDocument: The PDF document to diagnose
    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument) {
        // Log basic document info
        let pdfData = pdfDocument.dataRepresentation()
        print("TextExtractionService: PDF data size: \(pdfData?.count ?? 0) bytes")
        print("TextExtractionService: PDF has \(pdfDocument.pageCount) pages")
        
        // Log info for each page
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                let pageRect = page.bounds(for: .mediaBox)
                let pageSize = pageRect.size
                print("TextExtractionService: Page \(i+1) size: \(pageSize.width) x \(pageSize.height)")
                print("TextExtractionService: Page \(i+1) rotation: \(page.rotation)")
                
                // Check if page has text
                if let text = page.string, !text.isEmpty {
                    print("TextExtractionService: Page \(i+1) has \(text.count) characters of text")
                } else {
                    print("TextExtractionService: Page \(i+1) has no text content, may be image-only")
                }
            }
        }
    }
    
    /// Checks if a PDF document is valid and contains text
    /// - Parameter pdfDocument: The PDF document to validate
    /// - Returns: True if the document is valid and has text content
    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool {
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), 
               let text = page.string, 
               !text.isEmpty {
                return true
            }
        }
        return false
    }
} 