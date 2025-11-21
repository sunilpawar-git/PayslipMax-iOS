import Foundation
import PDFKit

/// Protocol for PDF extraction
protocol PDFExtractorProtocol {
    /// Extracts payslip data from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract data from
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    /// - Throws: An error if parsing fails.
    func extractPayslipData(from pdfDocument: PDFDocument) async throws -> PayslipItem?

    /// Extracts payslip data from extracted text
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    /// - Throws: An error if parsing fails.
    func extractPayslipData(from text: String) async throws -> PayslipItem?

    /// Extracts text from a PDF document. Handles large documents asynchronously.
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from pdfDocument: PDFDocument) async -> String

    /// Gets the available parsers
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String]
}
