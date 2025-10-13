import Foundation
import PDFKit

/// Simplified PDF processing service focused on essential payslip extraction
/// Replaces complex pipeline with direct SimplifiedPayslipParser integration
@MainActor
class SimplifiedPDFProcessingService {
    
    // MARK: - Properties
    
    private let parser: SimplifiedPayslipParser
    private let textExtractionService: PDFTextExtractionServiceProtocol
    
    // MARK: - Initialization
    
    init(
        parser: SimplifiedPayslipParser = SimplifiedPayslipParser(),
        textExtractionService: PDFTextExtractionServiceProtocol
    ) {
        self.parser = parser
        self.textExtractionService = textExtractionService
    }
    
    // MARK: - Processing Methods
    
    /// Processes PDF data and returns a SimplifiedPayslip
    /// - Parameter data: Raw PDF data
    /// - Returns: Result containing SimplifiedPayslip or error
    func processPDFData(_ data: Data) async -> Result<SimplifiedPayslip, PDFProcessingError> {
        print("[SimplifiedPDFProcessingService] Processing PDF of size: \(data.count) bytes")
        
        // Step 1: Extract text from PDF
        guard let pdfDocument = PDFDocument(data: data) else {
            return .failure(.invalidFormat)
        }
        
        guard let text = textExtractionService.extractText(from: pdfDocument, callback: nil) else {
            print("[SimplifiedPDFProcessingService] Text extraction failed")
            return .failure(.extractionFailed("Failed to extract text from PDF"))
        }
        
        // Step 2: Parse text using simplified parser
        let payslip = await parser.parse(text, pdfData: data)
        
        print("[SimplifiedPDFProcessingService] Parsed payslip: \(payslip.name), Confidence: \(payslip.parsingConfidence)")
        
        return .success(payslip)
    }
    
    /// Processes PDF from URL
    /// - Parameter url: URL of PDF file
    /// - Returns: Result containing SimplifiedPayslip or error
    func processPDF(from url: URL) async -> Result<SimplifiedPayslip, PDFProcessingError> {
        print("[SimplifiedPDFProcessingService] Processing PDF from URL: \(url)")
        
        do {
            let data = try Data(contentsOf: url)
            return await processPDFData(data)
        } catch {
            print("[SimplifiedPDFProcessingService] Error loading PDF: \(error)")
            return .failure(.fileAccessError(error.localizedDescription))
        }
    }
}

