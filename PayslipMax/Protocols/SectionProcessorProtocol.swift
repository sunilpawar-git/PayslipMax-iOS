import Foundation

/// Protocol for processing payslip sections (earnings or deductions)
/// This protocol defines the interface for extracting and processing financial data sections
protocol SectionProcessorProtocol {
    /// Process a section of text and extract financial items
    /// - Parameter sectionText: The text content of the section to process
    /// - Returns: Dictionary of extracted items with their amounts
    func extractItems(from sectionText: String) -> [String: Double]

    /// Process individual items and categorize them into the data structure
    /// - Parameters:
    ///   - items: Dictionary of items to process
    ///   - data: The data structure to update with processed items
    func processItems(_ items: [String: Double], into data: inout EarningsDeductionsData)

    /// The section type this processor handles
    var sectionType: ProcessorSectionType { get }
}

/// Enumeration of section types for better type safety
enum ProcessorSectionType {
    case earnings
    case deductions

    var headerPattern: String {
        switch self {
        case .earnings:
            return "EARNINGS[\\s\\S]*?Description\\s+Amount"
        case .deductions:
            return "DEDUCTIONS[\\s\\S]*?Description\\s+Amount"
        }
    }

    var sectionName: String {
        switch self {
        case .earnings:
            return "EARNINGS"
        case .deductions:
            return "DEDUCTIONS"
        }
    }
}
