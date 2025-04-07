import Foundation
import PDFKit
// Add import for the shared PageType

/// Service for extracting text from PDF documents
class PDFTextExtractor {
    // MARK: - Public Methods
    
    /// Extracts text from all pages of a PDF document
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from pdfDocument: PDFDocument) -> String {
        var extractedText = ""
        
        // Extract text from all pages
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                extractedText += extractText(from: page)
            }
        }
        
        return extractedText
    }
    
    /// Extracts text from all pages of a PDF document and returns an array of page texts
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: Array of page texts
    func extractPageTexts(from pdfDocument: PDFDocument) -> [String] {
        var pageTexts: [String] = []
        
        // Extract text from all pages
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                pageTexts.append(extractText(from: page))
            }
        }
        
        return pageTexts
    }
    
    /// Identifies the type of each page in the document
    /// - Parameter pageTexts: Array of page texts
    /// - Returns: Array of page types
    func identifyPageTypes(_ pageTexts: [String]) -> [PageType] {
        var pageTypes: [PageType] = []
        
        for pageText in pageTexts {
            if pageText.contains("STATEMENT OF ACCOUNT FOR") {
                pageTypes.append(.mainSummary)
            } else if pageText.contains("INCOME TAX DETAILS") {
                pageTypes.append(.incomeTaxDetails)
            } else if pageText.contains("DSOP FUND FOR THE CURRENT YEAR") {
                pageTypes.append(.dsopFundDetails)
            } else if pageText.contains("CONTACT US") {
                pageTypes.append(.contactDetails)
            } else {
                pageTypes.append(.other)
            }
        }
        
        return pageTypes
    }
    
    // MARK: - Private Methods
    
    /// Extracts text from a single PDF page using multiple methods
    /// - Parameter page: The PDF page to extract text from
    /// - Returns: The extracted text
    private func extractText(from page: PDFPage) -> String {
        var pageText = ""
        
        // Try primary method
        if let text = page.string {
            pageText += text
        } else {
            // Try alternate methods
            for annotation in page.annotations {
                pageText += annotation.contents ?? ""
            }
            
            if let attributedString = page.attributedString {
                pageText += attributedString.string
            }
        }
        
        return pageText
    }
} 