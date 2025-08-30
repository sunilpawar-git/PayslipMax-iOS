import Foundation
import PDFKit

/// Protocol for payslip format detection service
protocol PayslipFormatDetectionServiceProtocol {
    /// Detects the format of a payslip from PDF data. Handles text extraction asynchronously.
    /// - Parameter data: The PDF data to analyze
    /// - Returns: The detected payslip format
    func detectFormat(_ data: Data) async -> PayslipFormat

    /// Detects the format of a payslip from PDF document using AI when available
    /// - Parameter document: The PDF document to analyze
    /// - Returns: The detected payslip format
    func detectFormat(from document: PDFDocument) async -> PayslipFormat

    /// Detects the format of a payslip from extracted text
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: The detected payslip format
    func detectFormat(fromText text: String) -> PayslipFormat

    /// Detects format with detailed analysis including confidence and reasoning
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Detailed format detection result with confidence and reasoning
    func detectFormatDetailed(from document: PDFDocument) async -> FormatDetectionResult?
} 