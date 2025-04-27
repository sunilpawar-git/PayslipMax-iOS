import Foundation
import PDFKit

/// Default implementation of the PDFExtractorProtocol.
///
/// This class provides a basic implementation of PDF data extraction
/// for payslip documents.
class DefaultPDFExtractor: PDFExtractorProtocol {
    // MARK: - Properties
    
    /// The underlying coordinator responsible for the actual extraction and parsing logic.
    private let coordinator: PDFExtractionCoordinatorProtocol
    
    // MARK: - Initialization
    
    /// Initializes the default extractor, creating a `PDFExtractionCoordinator`.
    /// - Parameter useEnhancedParser: Flag to indicate if the enhanced parser should be used by the coordinator.
    init(useEnhancedParser: Bool = true) {
        self.coordinator = PDFExtractionCoordinator(useEnhancedParser: useEnhancedParser)
    }
    
    // MARK: - PDFExtractorProtocol
    
    /// Extracts payslip data from a PDF document.
    /// Delegates the extraction process to the internal coordinator.
    /// - Parameter pdfDocument: The PDF document to extract data from.
    /// - Returns: A `PayslipItem` containing the extracted data, or nil if extraction fails.
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        return coordinator.extractPayslipData(from: pdfDocument)
    }
    
    /// Extracts payslip data from extracted text.
    /// Delegates the extraction process to the internal coordinator.
    /// - Parameter text: The text extracted from a PDF.
    /// - Returns: A `PayslipItem` if extraction is successful, nil otherwise.
    func extractPayslipData(from text: String) -> PayslipItem? {
        return coordinator.extractPayslipData(from: text)
    }
    
    /// Extracts text from a PDF document.
    /// Delegates the text extraction to the internal coordinator.
    /// Handles large documents asynchronously.
    /// - Parameter document: The PDF document to extract text from.
    /// - Returns: The extracted text as a single string.
    func extractText(from pdfDocument: PDFDocument) async -> String {
        // Delegate to the coordinator, which now handles async extraction.
        // Note: We assume PDFExtractionCoordinatorProtocol.extractText is now async.
        // If not, this will cause a build error, and we need to update that protocol/implementation too.
        return await coordinator.extractText(from: pdfDocument)
    }
    
    /// Gets the names of the available parsers from the coordinator.
    /// - Returns: An array of available parser names.
    func getAvailableParsers() -> [String] {
        return coordinator.getAvailableParsers()
    }
    
    /// Parses payslip data from text.
    /// Delegates the parsing to the internal coordinator's extraction method.
    /// - Parameter text: The text to parse.
    /// - Returns: A `PayslipItem` containing the parsed data, or nil if parsing fails.
    func parsePayslipData(from text: String) -> PayslipItem? {
        return coordinator.extractPayslipData(from: text)
    }
}
