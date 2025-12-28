import Foundation
import PDFKit

/// A processing pipeline step responsible for constructing a `PayslipItem` instance
/// from processed financial data and metadata.
/// It synthesizes the final model object, applying fallback logic for missing date information
/// and calculating derived fields like "Other Allowances" or "Other Deductions".
@MainActor
class PayslipCreationProcessingStep: PayslipProcessingStep {
    typealias Input = (Data, [String: Double], String?, Int?)
    typealias Output = PayslipItem

    /// The data extraction service
    private let dataExtractionService: DataExtractionService

    /// Known earning codes that can be extracted from payslips
    private static let knownEarningCodes = ["BPAY", "DA", "MSP", "RH12", "TPTA", "TPTADA", "ARR-RSHNA", "RSHNA", "HRA", "TA", "CEA", "TPT", "WASHIA", "OUTFITA"]

    /// Known deduction codes that can be extracted from payslips
    private static let knownDeductionCodes = ["DSOP", "AGIF", "ITAX", "EHCESS"]

    /// Initialize with required services
    /// - Parameter dataExtractionService: Service for extracting data from text
    init(dataExtractionService: DataExtractionService) {
        self.dataExtractionService = dataExtractionService
    }

    /// Processes the input tuple to create a finalized `PayslipItem`.
    /// Uses provided financial data, month, and year. Falls back to the current month/year if not provided.
    /// Calculates "Other Allowances" and "Other Deductions" based on the difference between reported totals
    /// and the sum of known itemized components.
    /// - Parameter input: A tuple containing (`pdfData`, `financialData`, `month?`, `year?`).
    /// - Returns: A `Result` containing the created `PayslipItem` on success, or a `PDFProcessingError` on failure.
    func process(_ input: (Data, [String: Double], String?, Int?)) async -> Result<PayslipItem, PDFProcessingError> {
        let startTime = Date()
        defer {
            print("[PayslipCreationStep] Completed in \(Date().timeIntervalSince(startTime)) seconds")
        }

        let (pdfData, financialData, month, year) = input

        let credits = financialData["credits"] ?? 0.0
        let debits = financialData["debits"] ?? 0.0
        let dsop = financialData["DSOP"] ?? 0.0
        let tax = financialData["ITAX"] ?? 0.0

        let (payslipMonth, payslipYear) = resolveMonthYear(providedMonth: month, providedYear: year)

        let payslipItem = createPayslipItem(
            pdfData: pdfData,
            month: payslipMonth,
            year: payslipYear,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax
        )

        let earnings = extractEarnings(from: financialData, totalCredits: credits)
        let deductions = extractDeductions(from: financialData, totalDebits: debits)

        payslipItem.earnings = earnings
        payslipItem.deductions = deductions

        print("[PayslipCreationStep] Created payslip with extracted data - credits: \(credits), debits: \(debits)")
        return .success(payslipItem)
    }

    // MARK: - Private Helpers

    private func resolveMonthYear(providedMonth: String?, providedYear: Int?) -> (String, Int) {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let currentMonth = dateFormatter.string(from: currentDate)

        return (providedMonth ?? currentMonth, providedYear ?? currentYear)
    }

    private func createPayslipItem(pdfData: Data, month: String, year: Int, credits: Double, debits: Double, dsop: Double, tax: Double) -> PayslipItem {
        PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: "Military Personnel",
            accountNumber: "",
            panNumber: "",
            pdfData: pdfData
        )
    }

    private func extractEarnings(from financialData: [String: Double], totalCredits: Double) -> [String: Double] {
        var earnings = extractKnownItems(from: financialData, codes: Self.knownEarningCodes)

        let knownTotal = earnings.values.reduce(0, +)
        if totalCredits > knownTotal && knownTotal > 0 {
            let otherAllowances = totalCredits - knownTotal
            if otherAllowances > 0 {
                earnings["Other Allowances"] = otherAllowances
            }
        }

        return earnings
    }

    private func extractDeductions(from financialData: [String: Double], totalDebits: Double) -> [String: Double] {
        var deductions = extractKnownItems(from: financialData, codes: Self.knownDeductionCodes)

        let knownTotal = deductions.values.reduce(0, +)
        if totalDebits > knownTotal && knownTotal > 0 {
            let otherDeductions = totalDebits - knownTotal
            if otherDeductions > 0 {
                deductions["Other Deductions"] = otherDeductions
            }
        }

        return deductions
    }

    private func extractKnownItems(from financialData: [String: Double], codes: [String]) -> [String: Double] {
        var result: [String: Double] = [:]
        for code in codes {
            if let value = financialData[code] {
                result[code] = value
            }
        }
        return result
    }
}
