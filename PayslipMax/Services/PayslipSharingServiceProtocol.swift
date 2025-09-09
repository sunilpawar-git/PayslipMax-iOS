import Foundation

/// Protocol for payslip sharing functionality
/// Part of the unified architecture for consistent sharing across the app
protocol PayslipSharingServiceProtocol {
    /// Gets a formatted string representation of the payslip for sharing
    ///
    /// - Parameter payslipData: The payslip data to format
    /// - Returns: A formatted string with payslip details
    func getShareText(for payslipData: PayslipData) -> String

    /// Gets both text and PDF data for sharing if available
    ///
    /// - Parameters:
    ///   - payslipData: The payslip data
    ///   - payslip: The payslip item (if available)
    /// - Returns: An array of items to share
    func getShareItems(for payslipData: PayslipData, payslip: AnyPayslip?) async -> [Any]

    /// Get the URL for sharing the PDF
    ///
    /// - Parameter payslip: The payslip to get PDF for
    /// - Returns: URL to the PDF file
    /// - Throws: Error if PDF cannot be prepared
    func getPDFURL(for payslip: AnyPayslip) async throws -> URL?
}
