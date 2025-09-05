import Foundation

/// Protocol defining the interface for tabular data extraction services.
///
/// This protocol abstracts tabular data extraction functionality to enable
/// dependency injection, testing, and different extraction strategies.
/// It focuses specifically on parsing structured tabular data commonly
/// found in payslip documents.
///
/// ## Usage
/// Implementations should:
/// - Parse tabular financial data from text
/// - Categorize extracted data into earnings and deductions
/// - Handle various tabular formats and layouts
/// - Support code-value pair extraction
protocol TabularDataExtractorProtocol {
    
    /// Extracts tabular structure from text and categorizes financial data.
    ///
    /// This method parses text that contains financial data in a tabular format,
    /// extracting code-value pairs and categorizing them as either earnings or deductions.
    /// It modifies the provided dictionaries in-place for performance reasons.
    ///
    /// - Parameters:
    ///   - text: The input text containing tabular financial data
    ///   - earnings: An inout dictionary to collect earnings data
    ///   - deductions: An inout dictionary to collect deductions data
    func extractTabularStructure(from text: String, into earnings: inout [String: Double], and deductions: inout [String: Double])
}
