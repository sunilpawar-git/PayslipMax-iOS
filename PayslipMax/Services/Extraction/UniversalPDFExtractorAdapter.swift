import Foundation
import PDFKit

/// Adapter to use UniversalPayslipProcessor as a PDFExtractorProtocol.
/// This ensures that the PDFExtractorProtocol contract is fulfilled using the single source of truth.
final class PDFExtractorAdapter: PDFExtractorProtocol {

    private let universalProcessor: UniversalPayslipProcessor
    private let pdfTextExtractor: DefaultTextExtractor

    init() {
        self.universalProcessor = UniversalPayslipProcessor()
        self.pdfTextExtractor = DefaultTextExtractor()
    }

    /// Extracts payslip data from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract data from
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    /// - Throws: An error if parsing fails.
    func extractPayslipData(from pdfDocument: PDFDocument) async throws -> PayslipItem? {
        let text = await extractText(from: pdfDocument)
        return try await universalProcessor.processPayslip(from: text)
    }

    /// Extracts payslip data from extracted text
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    /// - Throws: An error if parsing fails.
    func extractPayslipData(from text: String) async throws -> PayslipItem? {
        return try await universalProcessor.processPayslip(from: text)
    }

    /// Extracts text from a PDF document. Handles large documents asynchronously.
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from pdfDocument: PDFDocument) async -> String {
        return await pdfTextExtractor.extractText(from: pdfDocument)
    }

    /// Gets the available parsers
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String] {
        return ["UniversalPayslipProcessor"]
    }
}
