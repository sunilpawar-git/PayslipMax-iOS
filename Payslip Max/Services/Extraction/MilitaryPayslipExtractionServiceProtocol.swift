import Foundation
import PDFKit

/// Protocol for extracting data from military payslips
protocol MilitaryPayslipExtractionServiceProtocol {
    /// Determines if the text appears to be from a military payslip
    /// - Parameter text: The text to analyze
    /// - Returns: True if the text appears to be from a military payslip
    func isMilitaryPayslip(_ text: String) -> Bool
    
    /// Extracts data from military payslips
    /// - Parameters:
    ///   - text: The text to extract from
    ///   - pdfData: Optional PDF data to include in the result
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    /// - Throws: An error if extraction fails
    func extractMilitaryPayslipData(from text: String, pdfData: Data?) throws -> PayslipItem?
    
    /// Extracts tabular data from military payslips
    /// - Parameter text: The text to extract tabular data from
    /// - Returns: A tuple containing dictionaries of earnings and deductions
    func extractMilitaryTabularData(from text: String) -> ([String: Double], [String: Double])
} 