import Foundation
import PDFKit

/// Protocol defining the functionality for extracting data from PDF documents.
///
/// This protocol provides a common interface for different implementations
/// of PDF data extraction, allowing for better testability and flexibility.
protocol PDFExtractorProtocol {
    /// Extracts payslip data from a PDF document.
    ///
    /// - Parameter document: The PDF document to extract data from.
    /// - Returns: A payslip item containing the extracted data.
    /// - Throws: An error if extraction fails.
    func extractPayslipData(from document: PDFDocument) async throws -> any PayslipItemProtocol
    
    /// Parses payslip data from text.
    ///
    /// - Parameter text: The text to parse.
    /// - Returns: A payslip item containing the parsed data.
    /// - Throws: An error if parsing fails.
    func parsePayslipData(from text: String) throws -> any PayslipItemProtocol
}

/// Errors that can occur during PDF extraction.
enum PDFExtractionError: Error, LocalizedError {
    /// The PDF document is invalid.
    case invalidDocument
    
    /// Failed to extract text from the PDF.
    case textExtractionFailed
    
    /// Failed to parse the extracted text.
    case parsingFailed(String)
    
    /// Error description for user-facing messages.
    var errorDescription: String? {
        switch self {
        case .invalidDocument:
            return "The PDF document is invalid"
        case .textExtractionFailed:
            return "Failed to extract text from the PDF"
        case .parsingFailed(let reason):
            return "Failed to parse the extracted text: \(reason)"
        }
    }
} 