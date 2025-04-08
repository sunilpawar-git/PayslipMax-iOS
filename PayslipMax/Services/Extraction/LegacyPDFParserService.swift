import Foundation
import PDFKit

/// Protocol for legacy PDF parser service
protocol LegacyPDFParserServiceProtocol {
    /// Extracts payslip data using the legacy parser
    /// - Parameters:
    ///   - document: The PDF document to extract data from
    ///   - pdfData: Optional PDF data to include in the result
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    /// - Throws: An error if extraction fails
    func extractPayslipData(from document: PDFDocument, pdfData: Data?) throws -> PayslipItem?
    
    /// Gets an image from a PDF page
    /// - Parameter page: The PDF page to extract image from
    /// - Returns: UIImage if extraction is successful, nil otherwise
    func getPageImage(from page: PDFPage) -> UIImage?
}

/// Service for handling legacy PDF parsing operations
class LegacyPDFParserService: LegacyPDFParserServiceProtocol {
    
    // MARK: - Properties
    
    private let textExtractionService: TextExtractionServiceProtocol
    private let patternMatchingService: PatternMatchingServiceProtocol
    
    // MARK: - Initialization
    
    init(textExtractionService: TextExtractionServiceProtocol? = nil,
         patternMatchingService: PatternMatchingServiceProtocol? = nil) {
        self.textExtractionService = textExtractionService ?? TextExtractionService()
        self.patternMatchingService = patternMatchingService ?? PatternMatchingService()
    }
    
    // MARK: - Public Methods
    
    /// Extracts payslip data using the legacy parser
    /// - Parameters:
    ///   - document: The PDF document to extract data from
    ///   - pdfData: Optional PDF data to include in the result
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    /// - Throws: An error if extraction fails
    func extractPayslipData(from document: PDFDocument, pdfData: Data?) throws -> PayslipItem? {
        var extractedText = ""
        
        print("LegacyPDFParserService: Starting extraction from PDF with \(document.pageCount) pages")
        
        // Check if we have any pages
        if document.pageCount == 0 {
            print("LegacyPDFParserService: PDF has no pages")
            throw AppError.pdfExtractionFailed("PDF has no pages")
        }
        
        // Track if we successfully extracted any text
        var extractedAnyText = false
        
        // Extract text from each page
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            
            if let pageText = page.string, !pageText.isEmpty {
                print("LegacyPDFParserService: Page \(i+1) text length: \(pageText.count) characters")
                extractedText += pageText + "\n\n"
                extractedAnyText = true
            } else {
                print("LegacyPDFParserService: Page \(i+1) text length: 0 characters, may be an image")
                
                // If the page has no text, try to extract the page image
                if let pageImage = getPageImage(from: page) {
                    print("LegacyPDFParserService: Got image from page \(i+1), size: \(pageImage.size.width) x \(pageImage.size.height)")
                    
                    // Try OCR on the page image (this would be a place to integrate Vision framework)
                    // For now, we just acknowledge the image-only content
                    print("LegacyPDFParserService: Image-only content detected on page \(i+1)")
                }
            }
        }
        
        // If we didn't extract any text, handle as an image-only PDF
        if !extractedAnyText {
            print("LegacyPDFParserService: No text extracted from PDF")
            throw AppError.pdfExtractionFailed("Text extraction failed")
        }
        
        print("LegacyPDFParserService: Total extracted text length: \(extractedText.count) characters")
        print("LegacyPDFParserService: First 200 characters of extracted text: \(String(extractedText.prefix(200)))")
        
        // Extract data from the text
        let extractedData = patternMatchingService.extractData(from: extractedText)
        
        // Extract tabular data
        let (earnings, deductions) = patternMatchingService.extractTabularData(from: extractedText)
        
        // Create a PayslipItem from the extracted data
        return try createPayslipItem(from: extractedData, earnings: earnings, deductions: deductions, text: extractedText, pdfData: pdfData)
    }
    
    /// Gets an image from a PDF page
    /// - Parameter page: The PDF page to extract image from
    /// - Returns: UIImage if extraction is successful, nil otherwise
    func getPageImage(from page: PDFPage) -> UIImage? {
        let pageRect = page.bounds(for: .mediaBox)
        
        // Create a higher resolution context
        let scale: CGFloat = 2.0
        let width = pageRect.width * scale
        let height = pageRect.height * scale
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        // Fill with white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Flip the context coordinate system
        context.translateBy(x: 0, y: height)
        context.scaleBy(x: scale, y: -scale)
        
        // Draw the page
        page.draw(with: .mediaBox, to: context)
        
        // Get the image
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // MARK: - Private Methods
    
    /// Creates a PayslipItem from extracted data
    /// - Parameters:
    ///   - extractedData: Dictionary of extracted data
    ///   - earnings: Dictionary of earnings
    ///   - deductions: Dictionary of deductions
    ///   - text: The original text
    ///   - pdfData: Optional PDF data to include in the result
    /// - Returns: A PayslipItem if creation is successful, nil otherwise
    /// - Throws: An error if creation fails
    private func createPayslipItem(from extractedData: [String: String], 
                                  earnings: [String: Double], 
                                  deductions: [String: Double], 
                                  text: String, 
                                  pdfData: Data?) throws -> PayslipItem? {
        // This would normally call the PayslipBuilderService to create the PayslipItem
        // For now, we'll return nil as a placeholder
        return nil
    }
} 