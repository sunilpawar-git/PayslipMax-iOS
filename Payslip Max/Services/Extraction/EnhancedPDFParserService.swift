import Foundation
import PDFKit

/// Protocol for enhanced PDF parser service
protocol EnhancedPDFParserServiceProtocol {
    /// Extracts payslip data using the enhanced parser
    /// - Parameters:
    ///   - document: The PDF document to extract data from
    ///   - pdfData: Optional PDF data to include in the result
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    /// - Throws: An error if extraction fails
    func extractPayslipData(from document: PDFDocument, pdfData: Data?) throws -> PayslipItem?
}

/// Service for handling enhanced PDF parsing operations
class EnhancedPDFParserService: EnhancedPDFParserServiceProtocol {
    
    // MARK: - Properties
    
    private let enhancedParser: EnhancedPDFParser
    
    // MARK: - Initialization
    
    init(enhancedParser: EnhancedPDFParser? = nil) {
        self.enhancedParser = enhancedParser ?? EnhancedPDFParser()
    }
    
    // MARK: - Public Methods
    
    /// Extracts payslip data using the enhanced parser
    /// - Parameters:
    ///   - document: The PDF document to extract data from
    ///   - pdfData: Optional PDF data to include in the result
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    /// - Throws: An error if extraction fails
    func extractPayslipData(from document: PDFDocument, pdfData: Data?) throws -> PayslipItem? {
        print("EnhancedPDFParserService: Using enhanced PDF parser...")
        
        // Parse the document using the enhanced parser
        let parsedData = try enhancedParser.parseDocument(document)
        
        // Check confidence score
        if parsedData.confidenceScore > 0.5 {
            print("EnhancedPDFParserService: Enhanced parser confidence score: \(parsedData.confidenceScore)")
            
            // Convert the parsed data to a PayslipItem
            guard let pdfData = pdfData ?? document.dataRepresentation() else {
                throw AppError.pdfExtractionFailed("Text extraction failed")
            }
            
            let payslipItem = PayslipParsingUtility.convertToPayslipItem(from: parsedData, pdfData: pdfData)
            
            // Normalize the pay components
            let normalizedPayslip = PayslipParsingUtility.normalizePayslipComponents(payslipItem)
            
            // Record the extraction for training purposes if document URL is available
            if let documentURL = document.documentURL {
                PDFExtractionTrainer.shared.recordExtraction(
                    extractedData: normalizedPayslip,
                    pdfURL: documentURL,
                    extractedText: parsedData.rawText
                )
            }
            
            return normalizedPayslip
        } else {
            print("EnhancedPDFParserService: Enhanced parser confidence score too low (\(parsedData.confidenceScore))")
            return nil
        }
    }
} 