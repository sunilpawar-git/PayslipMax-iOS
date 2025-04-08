import Foundation
import PDFKit

/// Protocol for services that manage PDF URLs for payslips
protocol PayslipPDFURLServiceProtocol {
    /// Get the URL for the payslip PDF, creating or repairing it if needed
    /// - Parameter payslip: The payslip item to get the PDF URL for
    /// - Returns: A URL to the PDF file, or nil if it couldn't be created
    /// - Throws: An error if the operation fails
    func getPDFURL(for payslip: any PayslipItemProtocol) async throws -> URL?
} 