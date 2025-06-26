import Foundation
import PDFKit

/// Handles efficient text extraction from PDF documents
final class PDFTextExtractionWrapper {
    
    // MARK: - Properties
    
    private let textExtractionService: PDFTextExtractionService
    weak var delegate: PDFTextExtractionDelegate?
    
    // MARK: - Initialization
    
    init(textExtractionService: PDFTextExtractionService) {
        self.textExtractionService = textExtractionService
        self.textExtractionService.delegate = self
    }
    
    // MARK: - Text Extraction
    
    /// Extracts full text from a PDF document using memory-efficient streaming approach
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text, or nil if extraction fails
    func extractFullText(from document: PDFDocument) -> String? {
        print("[PDFTextExtractor] Starting memory-efficient text extraction for document with \(document.pageCount) pages")
        
        let startTime = Date()
        let text = textExtractionService.extractText(from: document) { (pageText, currentPage, totalPages) in
            // Log progress for long documents
            if totalPages > 5 && currentPage % 5 == 0 {
                print("[PDFTextExtractor] Extraction progress: \(currentPage)/\(totalPages) pages")
            }
        }
        
        // Log extraction results
        let processingTime = Date().timeIntervalSince(startTime)
        if let text = text {
            print("[PDFTextExtractor] Text extraction completed in \(String(format: "%.2f", processingTime)) seconds")
            print("[PDFTextExtractor] Extracted \(text.count) characters")
            return text
        } else {
            print("[PDFTextExtractor] Text extraction failed")
            return nil
        }
    }
    
    /// Extracts text from a specific page
    /// - Parameters:
    ///   - document: The PDF document
    ///   - pageIndex: The page index to extract from
    /// - Returns: The extracted text from the page, or nil if extraction fails
    func extractText(from document: PDFDocument, pageIndex: Int) -> String? {
        guard pageIndex >= 0 && pageIndex < document.pageCount else {
            print("[PDFTextExtractor] Invalid page index: \(pageIndex)")
            return nil
        }
        
        guard let page = document.page(at: pageIndex) else {
            print("[PDFTextExtractor] Could not get page at index: \(pageIndex)")
            return nil
        }
        
        return page.string
    }
    
    /// Checks if a PDF document has extractable text
    /// - Parameter document: The PDF document to check
    /// - Returns: True if the document contains extractable text
    func hasExtractableText(_ document: PDFDocument) -> Bool {
        guard document.pageCount > 0 else { return false }
        
        // Check first page for text
        guard let firstPage = document.page(at: 0),
              let text = firstPage.string else {
            return false
        }
        
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Gets basic document information
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Basic document information
    func getDocumentInfo(_ document: PDFDocument) -> PDFDocumentInfo {
        let pageCount = document.pageCount
        let hasText = hasExtractableText(document)
        
        var estimatedTextLength = 0
        if hasText, let firstPageText = extractText(from: document, pageIndex: 0) {
            // Estimate total text length based on first page
            estimatedTextLength = firstPageText.count * pageCount
        }
        
        return PDFDocumentInfo(
            pageCount: pageCount,
            hasExtractableText: hasText,
            estimatedTextLength: estimatedTextLength
        )
    }
}

// MARK: - PDFTextExtractionDelegate

extension PDFTextExtractionWrapper: PDFTextExtractionDelegate {
    func textExtraction(didUpdateMemoryUsage memoryUsage: UInt64, delta: UInt64) {
        delegate?.textExtraction(didUpdateMemoryUsage: memoryUsage, delta: delta)
    }
}

// MARK: - Supporting Types

struct PDFDocumentInfo {
    let pageCount: Int
    let hasExtractableText: Bool
    let estimatedTextLength: Int
} 