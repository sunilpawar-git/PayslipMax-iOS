import Foundation
import PDFKit

/// Protocol for payslip format detection service
protocol PayslipFormatDetectionServiceProtocol {
    /// Detects the format of a payslip from PDF data. Handles text extraction asynchronously.
    /// - Parameter data: The PDF data to analyze
    /// - Returns: The detected payslip format
    func detectFormat(_ data: Data) async -> PayslipFormat

    /// Detects the format of a payslip from extracted text
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: The detected payslip format
    func detectFormat(fromText text: String) -> PayslipFormat

    /// Updates the user-provided parsing hint to bias detection without disabling auto-detect
    func updateUserHint(_ hint: PayslipUserHint)
}
