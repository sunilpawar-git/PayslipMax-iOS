import Foundation
import PDFKit

// swiftlint:disable no_hardcoded_strings
/// Protocol defining extraction result assembly capabilities.
///
/// This service handles the conversion of extracted data dictionary into
/// structured PayslipItem objects, including financial data extraction,
/// earnings/deductions processing, and data validation.
protocol ExtractionResultAssemblerProtocol {
    /// Assembles a PayslipItem from extracted data and PDF data.
    /// - Parameters:
    ///   - data: Dictionary of extracted key-value pairs
    ///   - pdfData: Raw PDF data to include in the PayslipItem
    /// - Returns: A configured PayslipItem
    /// - Throws: ExtractionError if essential data is missing
    func assemblePayslipItem(from data: [String: String], pdfData: Data) throws -> PayslipItem
}

/// Service responsible for assembling PayslipItem objects from extracted data.
///
/// This service takes the raw extracted data dictionary and converts it into
/// a structured PayslipItem model. It handles financial calculations, validates
/// essential fields, and provides proper defaults for missing data.
class ExtractionResultAssembler: ExtractionResultAssemblerProtocol {

    /// Assembles a PayslipItem from extracted data and PDF data.
    /// - Parameters:
    ///   - data: Dictionary of extracted key-value pairs
    ///   - pdfData: Raw PDF data to include in the PayslipItem
    /// - Returns: A configured PayslipItem with all financial data properly calculated
    /// - Throws: ExtractionError if essential data is missing
    func assemblePayslipItem(from data: [String: String], pdfData: Data) throws -> PayslipItem {
        print("ExtractionResultAssembler: Creating PayslipItem from extracted data")

        // Extract required fields with default values
        let month = data["month"] ?? ""
        let yearString = data["year"] ?? ""
        let name = data["name"] ?? ""
        let accountNumber = data["account_number"] ?? ""
        let panNumber = data["pan_number"] ?? ""

        // Convert year to integer if needed
        let year = Int(yearString) ?? Calendar.current.component(.year, from: Date())

        // Extract and convert numeric values
        let (credits, debits, tax, dsop) = extractNumericValues(from: data)

        // Validate essential data
        if month.isEmpty || yearString.isEmpty || credits == 0 {
            print("ExtractionResultAssembler: Insufficient data extracted")
            throw ExtractionError.valueExtractionFailed
        }

        // Extract earnings and deductions if available
        let (earnings, deductions) = extractEarningsAndDeductions(from: data)

        // Create the payslip item
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: pdfData
        )

        // Set earnings and deductions
        payslip.earnings = earnings
        payslip.deductions = deductions

        print("ExtractionResultAssembler: Successfully created PayslipItem")
        return payslip
    }

    /// Extracts and converts numeric values from the data dictionary.
    /// - Parameter data: Dictionary containing extracted string values
    /// - Returns: Tuple of converted numeric values (credits, debits, tax, dsop)
    private func extractNumericValues(from data: [String: String]) -> (credits: Double, debits: Double, tax: Double, dsop: Double) {
        let credits = extractDouble(from: data["credits"] ?? "0")
        let debits = extractDouble(from: data["debits"] ?? "0")
        let tax = extractDouble(from: data["tax"] ?? "0")
        let dsop = extractDouble(from: data["dsop"] ?? "0")

        return (credits, debits, tax, dsop)
    }

    /// Extracts earnings and deductions from the data dictionary.
    /// - Parameter data: Dictionary containing extracted string values
    /// - Returns: Tuple of earnings and deductions dictionaries
    private func extractEarningsAndDeductions(from data: [String: String]) -> (earnings: [String: Double], deductions: [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        // Add entries with "earning_" or "deduction_" prefix
        for (key, value) in data {
            if key.starts(with: "earning_") {
                let amount = extractDouble(from: value)
                let earningName = String(key.dropFirst("earning_".count))
                earnings[earningName] = amount
            } else if key.starts(with: "deduction_") {
                let amount = extractDouble(from: value)
                let deductionName = String(key.dropFirst("deduction_".count))
                deductions[deductionName] = amount
            }
        }

        // If no detailed earnings, add a total
        let totalCredits = extractDouble(from: data["credits"] ?? "0")
        if earnings.isEmpty && totalCredits > 0 {
            earnings["Total Earnings"] = totalCredits
        }

        // If no detailed deductions, add defaults
        let totalDebits = extractDouble(from: data["debits"] ?? "0")
        let tax = extractDouble(from: data["tax"] ?? "0")
        let dsop = extractDouble(from: data["dsop"] ?? "0")

        if deductions.isEmpty && (totalDebits > 0 || tax > 0 || dsop > 0) {
            if tax > 0 {
                deductions["Tax"] = tax
            }
            if dsop > 0 {
                deductions["DSOP"] = dsop
            }
            if totalDebits > 0 && totalDebits > (tax + dsop) {
                deductions["Other Deductions"] = totalDebits - (tax + dsop)
            }
        }

        return (earnings, deductions)
    }

    /// Extracts a numerical (Double) value from a string.
    ///
    /// This utility function attempts to convert a string into a Double representation.
    /// It first cleans the string by removing any characters that are not digits (0-9) or a period (.) using a regular expression.
    /// Then, it attempts to initialize a Double from the cleaned string.
    ///
    /// - Parameter string: The string possibly containing a numerical value (e.g., "Rs. 1,234.56", "$5000").
    /// - Returns: The extracted Double value if the cleaned string is a valid number, otherwise `0.0`.
    private func extractDouble(from string: String) -> Double {
        // Remove currency symbols, commas, spaces
        let cleaned = string.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned) ?? 0.0
    }
}

// swiftlint:enable no_hardcoded_strings
