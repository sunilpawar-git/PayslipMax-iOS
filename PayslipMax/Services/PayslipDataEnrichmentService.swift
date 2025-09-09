import Foundation

/// Service responsible for enriching payslip data with additional information
/// Part of the unified architecture for consistent data enrichment across the app
@MainActor
class PayslipDataEnrichmentService: PayslipDataEnrichmentServiceProtocol {
    /// Enriches the payslip data with additional information from parsing
    ///
    /// - Parameters:
    ///   - payslipData: The current payslip data
    ///   - pdfData: The parsed PDF data dictionary
    /// - Returns: Enriched payslip data
    func enrichPayslipData(_ payslipData: PayslipData, with pdfData: [String: String]) -> PayslipData {
        // Create temporary data model from the parsed PDF data for merging
        var tempData = PayslipData(from: PayslipItemFactory.createEmpty() as AnyPayslip)

        // Add data from PDF parsing
        for (key, value) in pdfData {
            // TODO: Add special handling for certain keys if needed

            // Example mapping logic:
            switch key.lowercased() {
            case "rank":
                tempData.rank = value
            case "name":
                tempData.name = value
            case "posting":
                tempData.postedTo = value
            // Add more mappings as needed
            default:
                break
            }
        }

        // Merge this data with our payslipData, but preserve core financial data
        return mergeParsedData(payslipData, with: tempData)
    }

    /// Merges parsed data while preserving core financial values
    ///
    /// - Parameters:
    ///   - payslipData: The original payslip data
    ///   - parsedData: The parsed data to merge
    /// - Returns: Merged payslip data
    func mergeParsedData(_ payslipData: PayslipData, with parsedData: PayslipData) -> PayslipData {
        var mergedData = payslipData

        // Personal details (can be overridden by PDF data if available)
        if !parsedData.name.isEmpty { mergedData.name = parsedData.name }
        if !parsedData.rank.isEmpty { mergedData.rank = parsedData.rank }
        if !parsedData.postedTo.isEmpty { mergedData.postedTo = parsedData.postedTo }

        // Don't override the core financial data from the original payslip
        // (totalCredits, totalDebits, dsop, incomeTax, netRemittance remain unchanged)

        return mergedData
    }
}
