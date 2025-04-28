import Foundation
import PDFKit

/// Protocol defining the interface for extracting data specifically from military payslips.
///
/// This protocol outlines the necessary methods to identify a military payslip and extract
/// both general information and detailed tabular data (earnings, deductions) from its text content.
protocol MilitaryPayslipExtractionServiceProtocol {
    /// Determines if the provided text content likely originates from a military payslip.
    ///
    /// Implementations should check for specific markers (e.g., "PCDA", "Defence Accounts") or
    /// a sufficient number of common military terms (e.g., "Rank", "Service No", "MSP") to make a determination.
    ///
    /// - Parameter text: The text content extracted from a PDF or other source to analyze.
    /// - Returns: `true` if the text is identified as a potential military payslip, `false` otherwise.
    func isMilitaryPayslip(_ text: String) -> Bool
    
    /// Extracts structured data from text identified as belonging to a military payslip.
    ///
    /// This method should parse the input text to extract key fields (name, month, year, etc.)
    /// and detailed financial data (earnings, deductions, totals). It should then assemble
    /// this information into a `PayslipItem`.
    ///
    /// - Parameters:
    ///   - text: The extracted text content from the payslip.
    ///   - pdfData: Optional raw PDF data associated with the payslip text, to be stored in the `PayslipItem`.
    /// - Returns: A `PayslipItem` containing the structured extracted data if successful.
    /// - Throws: An error (e.g., `MilitaryExtractionError`) if extraction fails due to insufficient data, parsing errors, or other issues.
    func extractMilitaryPayslipData(from text: String, pdfData: Data?) throws -> PayslipItem?
    
    /// Extracts detailed tabular data (earnings and deductions) from military payslip text.
    ///
    /// This method focuses specifically on identifying and parsing the sections listing individual
    /// earnings components (like Basic Pay, MSP, DA) and deduction components (like ITAX, DSOP, AGIF),
    /// along with their corresponding amounts.
    ///
    /// - Parameter text: The text content to extract tabular financial data from.
    /// - Returns: A tuple containing two dictionaries:
    ///   - The first dictionary maps earning component names (String) to their amounts (Double).
    ///   - The second dictionary maps deduction component names (String) to their amounts (Double).
    func extractMilitaryTabularData(from text: String) -> ([String: Double], [String: Double])
} 