import Foundation
import PDFKit

/// Enhanced implementation of the PDFExtractorProtocol
class EnhancedPDFExtractorImpl: PDFExtractorProtocol {
    // MARK: - Properties
    
    /// The parsing coordinator for handling different parsing strategies
    private let parsingCoordinator: PDFParsingCoordinator
    
    // MARK: - Initialization
    
    /// Initializes a new EnhancedPDFExtractorImpl
    /// - Parameter parsingCoordinator: The parsing coordinator to use
    init(parsingCoordinator: PDFParsingCoordinator) {
        self.parsingCoordinator = parsingCoordinator
    }
    
    // MARK: - PDFExtractorProtocol
    
    /// Extracts payslip data from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract data from
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        // Use the parsing coordinator to parse the payslip
        return parsingCoordinator.parsePayslip(pdfDocument: pdfDocument)
    }
    
    /// Extracts text from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from pdfDocument: PDFDocument) -> String {
        var text = ""
        
        // Extract text from each page
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                text += pageText
                
                // Add a page separator if not the last page
                if i < pdfDocument.pageCount - 1 {
                    text += "\n\n--- Page \(i+1) ---\n\n"
                }
            }
        }
        
        return text
    }
    
    /// Gets the available parsers
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String] {
        return parsingCoordinator.getAvailableParsers()
    }
} 