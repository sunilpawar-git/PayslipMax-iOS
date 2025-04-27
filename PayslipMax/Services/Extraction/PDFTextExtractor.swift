import Foundation
import PDFKit
// Add import for the shared PageType

/// Service for extracting text from PDF documents
class PDFTextExtractor {
    // MARK: - Public Methods
    
    /// Extracts text from all pages of a PDF document. Handles potential large documents asynchronously.
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from pdfDocument: PDFDocument) async -> String {
        var extractedText = ""
        
        // Extract text from all pages asynchronously
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                // Await the text extraction for the page
                extractedText += await extractText(from: page)
            }
            // Yield to allow other tasks to run, especially for documents with many pages.
            await Task.yield()
        }
        
        return extractedText
    }
    
    /// Extracts text from all pages of a PDF document and returns an array of page texts. Handles asynchronously.
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: Array of page texts
    func extractPageTexts(from pdfDocument: PDFDocument) async -> [String] {
        var pageTexts: [String] = []
        
        // Extract text from all pages asynchronously
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                // Await the async helper call
                pageTexts.append(await extractText(from: page))
            }
            // Yield to allow other tasks to run
            await Task.yield()
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
    
    /// Extracts text from a single PDF page using multiple methods. This can be async for consistency, though operations are sync.
    /// - Parameter page: The PDF page to extract text from
    /// - Returns: The extracted text
    private func extractText(from page: PDFPage) async -> String {
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