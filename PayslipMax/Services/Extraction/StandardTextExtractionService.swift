import Foundation
import PDFKit

/// A standard implementation of text extraction from PDF documents
class StandardTextExtractionService {
    
    /// Extract text from the entire PDF document
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from document: PDFDocument) -> String {
        var extractedText = ""
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                if let pageText = page.string {
                    extractedText += pageText + "\n"
                }
            }
        }
        
        return extractedText
    }
    
    /// Extract text from a specific page of the PDF document
    /// - Parameters:
    ///   - pageIndex: The index of the page to extract text from
    ///   - document: The PDF document
    /// - Returns: The extracted text from the specified page
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        guard pageIndex >= 0, pageIndex < document.pageCount, let page = document.page(at: pageIndex) else {
            return nil
        }
        
        return page.string
    }
    
    /// Extract text from a range of pages in the PDF document
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - range: The range of pages to extract text from
    /// - Returns: The extracted text from the specified range
    func extractText(from document: PDFDocument, in range: Range<Int>) -> String {
        var extractedText = ""
        
        let startPage = max(0, range.lowerBound)
        let endPage = min(document.pageCount, range.upperBound)
        
        for i in startPage..<endPage {
            if let page = document.page(at: i), let pageText = page.string {
                extractedText += pageText + "\n"
            }
        }
        
        return extractedText
    }
} 