import Foundation
import PDFKit

/// Default implementation of the PDFExtractorProtocol.
///
/// This class provides a basic implementation of PDF data extraction
/// for payslip documents.
class DefaultPDFExtractor: PDFExtractorProtocol {
    // MARK: - Properties
    
    private let coordinator: PDFExtractionCoordinatorProtocol
    
    // MARK: - Initialization
    
    init(useEnhancedParser: Bool = true) {
        self.coordinator = PDFExtractionCoordinator(useEnhancedParser: useEnhancedParser)
    }
    
    // MARK: - PDFExtractorProtocol
    
    /// Extracts payslip data from a PDF document.
    ///
    /// - Parameter document: The PDF document to extract data from.
    /// - Returns: A payslip item containing the extracted data.
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        return coordinator.extractPayslipData(from: pdfDocument)
    }
    
    /// Extracts payslip data from extracted text.
    ///
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from text: String) -> PayslipItem? {
        return coordinator.extractPayslipData(from: text)
    }
    
    /// Extracts text from a PDF document.
    ///
    /// - Parameter document: The PDF document to extract text from.
    /// - Returns: The extracted text.
    func extractText(from pdfDocument: PDFDocument) -> String {
        return coordinator.extractText(from: pdfDocument)
    }
    
    /// Gets the available parsers.
    ///
    /// - Returns: Array of parser names.
    func getAvailableParsers() -> [String] {
        return coordinator.getAvailableParsers()
    }
    
    /// Parses payslip data from text.
    ///
    /// - Parameter text: The text to parse.
    /// - Returns: A payslip item containing the parsed data.
    func parsePayslipData(from text: String) -> PayslipItem? {
        return coordinator.extractPayslipData(from: text)
    }
}
