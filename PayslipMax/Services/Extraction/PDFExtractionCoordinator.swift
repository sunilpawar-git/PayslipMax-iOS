import Foundation
import PDFKit

/// Protocol defining the PDF extraction coordination functionality
protocol PDFExtractionCoordinatorProtocol {
    /// Extracts payslip data from a PDF document
    /// - Parameter document: The PDF document to extract data from
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from document: PDFDocument) -> PayslipItem?
    
    /// Extracts payslip data from text
    /// - Parameter text: The text to extract data from
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from text: String) -> PayslipItem?
    
    /// Extracts text from a PDF document. Handles large documents asynchronously.
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from document: PDFDocument) async -> String
    
    /// Gets the available parsers
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String]
}

/// Coordinator service that orchestrates the PDF extraction process
class PDFExtractionCoordinator: PDFExtractionCoordinatorProtocol {
    // MARK: - Properties
    
    private let useEnhancedParser: Bool
    private let textExtractionService: TextExtractionServiceProtocol
    private let validationService: PDFValidationServiceProtocol
    private let enhancedPDFParserService: EnhancedPDFParserServiceProtocol
    private let legacyPDFParserService: LegacyPDFParserServiceProtocol
    private let payslipParserService: PayslipParserServiceProtocol
    
    // MARK: - Initialization
    
    init(useEnhancedParser: Bool = true,
         textExtractionService: TextExtractionServiceProtocol? = nil,
         validationService: PDFValidationServiceProtocol? = nil,
         enhancedPDFParserService: EnhancedPDFParserServiceProtocol? = nil,
         legacyPDFParserService: LegacyPDFParserServiceProtocol? = nil,
         payslipParserService: PayslipParserServiceProtocol? = nil) {
        self.useEnhancedParser = useEnhancedParser
        self.textExtractionService = textExtractionService ?? TextExtractionService()
        self.validationService = validationService ?? PDFValidationService()
        self.enhancedPDFParserService = enhancedPDFParserService ?? EnhancedPDFParserService()
        self.legacyPDFParserService = legacyPDFParserService ?? LegacyPDFParserService(
            textExtractionService: self.textExtractionService,
            patternMatchingService: PatternMatchingService()
        )
        self.payslipParserService = payslipParserService ?? PayslipParserService()
    }
    
    // MARK: - PDFExtractionCoordinatorProtocol
    
    /// Extracts payslip data from a PDF document
    /// - Parameter document: The PDF document to extract data from
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from document: PDFDocument) -> PayslipItem? {
        do {
            // Validate the PDF document first
            try validationService.validatePDF(document)
            
            // Ensure we capture the PDF data before any extraction
            let pdfData = document.dataRepresentation()
            
            // Use the text extraction service for logging and diagnostics
            textExtractionService.logTextExtractionDiagnostics(for: document)
            
            if useEnhancedParser {
                return try extractPayslipDataUsingEnhancedParser(from: document, pdfData: pdfData)
            } else {
                return try extractPayslipDataUsingLegacyParser(from: document, pdfData: pdfData)
            }
        } catch {
            print("PDFExtractionCoordinator: Error extracting payslip data: \(error)")
            return nil
        }
    }
    
    /// Extracts payslip data from text
    /// - Parameter text: The text to extract data from
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from text: String) -> PayslipItem? {
        print("PDFExtractionCoordinator: Extracting payslip data from text only (no PDF data available)")
        return payslipParserService.parsePayslipData(from: text)
    }
    
    /// Extracts text from a PDF document. Handles large documents asynchronously.
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from document: PDFDocument) async -> String {
        // Must await the result from the underlying async service
        return await textExtractionService.extractText(from: document)
    }
    
    /// Gets the available parsers
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String] {
        return ["Enhanced Parser", "Legacy Parser"]
    }
    
    // MARK: - Private Methods
    
    /// Extracts payslip data using the enhanced parser
    /// - Parameters:
    ///   - document: The PDF document to extract data from
    ///   - pdfData: Optional PDF data to include in the result
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    /// - Throws: An error if extraction fails
    private func extractPayslipDataUsingEnhancedParser(from document: PDFDocument, pdfData: Data?) throws -> PayslipItem? {
        print("PDFExtractionCoordinator: Using enhanced PDF parser...")
        return try enhancedPDFParserService.extractPayslipData(from: document, pdfData: pdfData)
    }
    
    /// Extracts payslip data using the legacy parser
    /// - Parameters:
    ///   - document: The PDF document to extract data from
    ///   - pdfData: Optional PDF data to include in the result
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    /// - Throws: An error if extraction fails
    private func extractPayslipDataUsingLegacyParser(from document: PDFDocument, pdfData: Data?) throws -> PayslipItem? {
        print("PDFExtractionCoordinator: Using legacy PDF parser...")
        return try legacyPDFParserService.extractPayslipData(from: document, pdfData: pdfData)
    }
} 