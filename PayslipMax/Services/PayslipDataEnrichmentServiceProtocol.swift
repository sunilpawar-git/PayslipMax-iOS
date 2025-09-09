import Foundation

/// Protocol for payslip data enrichment functionality
/// Part of the unified architecture for consistent data enrichment across the app
protocol PayslipDataEnrichmentServiceProtocol {
    /// Enriches the payslip data with additional information from parsing
    ///
    /// - Parameters:
    ///   - payslipData: The current payslip data
    ///   - pdfData: The parsed PDF data dictionary
    /// - Returns: Enriched payslip data
    @MainActor func enrichPayslipData(_ payslipData: PayslipData, with pdfData: [String: String]) -> PayslipData

    /// Merges parsed data while preserving core financial values
    ///
    /// - Parameters:
    ///   - payslipData: The original payslip data
    ///   - parsedData: The parsed data to merge
    /// - Returns: Merged payslip data
    @MainActor func mergeParsedData(_ payslipData: PayslipData, with parsedData: PayslipData) -> PayslipData
}
