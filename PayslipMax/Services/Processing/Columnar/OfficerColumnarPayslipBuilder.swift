import Foundation

// swiftlint:disable no_hardcoded_strings
// The literals here are structural pay-code keys (DSOP, ITAX), metadata keys and a
// non-PII placeholder name — not user-facing copy. They mirror
// `UniversalPayslipProcessor.createPayslipItem` so columnar and regex paths agree.

/// Builds a `PayslipItem` from a **gate-accepted** `OfficerColumnarResult`.
///
/// Mirrors `UniversalPayslipProcessor.createPayslipItem`: credits/debits/net come from
/// the resolved totals, earnings/deductions are the verbatim columnar line items, and
/// `dsop`/`tax` are pulled by label. Identity (name/account/PAN) and the statement date
/// are derived from the first-page text via the shared `MilitaryDateExtractor`, so a
/// caller without that text gets the same safe defaults the regex path uses.
///
/// Stamps `metadata["parsing.path"] = "columnar"` so the pipeline (and tests) can prove
/// the offline columnar route handled the slip — no regex, no LLM, no network.
final class OfficerColumnarPayslipBuilder {
    private let dateExtractor: MilitaryDateExtractorProtocol

    init(dateExtractor: MilitaryDateExtractorProtocol? = nil) {
        self.dateExtractor = dateExtractor ?? MilitaryDateExtractor(
            datePatterns: DatePatternDefinitions(),
            dateValidation: DateValidationService(),
            dateProcessing: DateProcessingUtilities(),
            dateSelection: DateSelectionService(),
            confidenceCalculator: DateConfidenceCalculator()
        )
    }

    /// Builds the persisted item. `firstPageText` (date + identity) and `pdfData` are
    /// optional so the result alone is enough to construct a valid, reconciling item.
    func build(
        _ result: OfficerColumnarResult,
        firstPageText: String = "",
        pdfData: Data? = nil
    ) -> PayslipItem {
        let (month, year) = extractDateInfo(from: firstPageText)
        let (name, accountNumber, panNumber) = dateExtractor.extractPersonalInfo(from: firstPageText)

        let item = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: result.grossPay,
            debits: result.totalDeductions,
            dsop: deductionAmount(result.deductions, code: "DSOP"),
            tax: taxAmount(result.deductions),
            name: name ?? "Defense Personnel",
            accountNumber: accountNumber ?? "",
            panNumber: panNumber ?? "",
            pdfData: pdfData
        )

        item.earnings = result.earnings
        item.deductions = result.deductions
        item.metadata["parsing.path"] = "columnar"
        item.metadata["parsing.template"] = result.template == .oldFolded ? "oldFolded" : "newDirect"
        return item
    }

    // MARK: - Field derivation (mirrors UniversalPayslipProcessor)

    private func extractDateInfo(from firstPageText: String) -> (String, Int) {
        if let dateInfo = dateExtractor.extractStatementDate(from: firstPageText) {
            return (dateInfo.month, dateInfo.year)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return (formatter.string(from: Date()), Calendar.current.component(.year, from: Date()))
    }

    private func taxAmount(_ deductions: [String: Double]) -> Double {
        deductions["Income Tax"]
            ?? deductions["ITAX"]
            ?? deductions.first { $0.key.contains("ITAX") }?.value
            ?? 0.0
    }

    private func deductionAmount(_ deductions: [String: Double], code: String) -> Double {
        deductions[code] ?? deductions.first { $0.key.contains(code) }?.value ?? 0.0
    }
}

// swiftlint:enable no_hardcoded_strings
