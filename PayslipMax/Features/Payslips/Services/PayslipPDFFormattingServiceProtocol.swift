import Foundation
import PDFKit

/// Protocol for services that format and create PDF documents based on payslip data
protocol PayslipPDFFormattingServiceProtocol {
    /// Creates a professionally formatted PDF with payslip details
    /// - Parameters:
    ///   - payslipData: The parsed payslip data to format
    ///   - payslip: The payslip item containing metadata
    /// - Returns: Formatted PDF data
    func createFormattedPlaceholderPDF(from payslipData: PayslipData, payslip: AnyPayslip) -> Data
} 