import Foundation

// MARK: - PayslipDetailViewModel: Sharing

/// PDF sharing helpers and the breakdown-extraction utility.
/// Keeping these separate from the coordinator maintains SRP and
/// enables isolated testing of sharing logic.
extension PayslipDetailViewModel {

    // MARK: - PDF Sharing

    func getPDFURL() async throws -> URL? {
        try await pdfHandler.getPDFURL()
    }

    func getShareItems() async -> [Any] {
        let data = await pdfHandler.getPDFDataForSharing()
        let items = formatterService.getShareItems(for: payslipData, pdfData: data)
        stateManager.cacheShareItems(items)
        return items
    }

    func getShareItemsSync() -> [Any]? {
        if let cached = stateManager.getCachedShareItems() {
            return cached
        }
        let items = formatterService.getShareItems(for: payslipData, pdfData: pdfHandler.pdfData)
        stateManager.cacheShareItems(items)
        return items
    }

    // MARK: - Breakdown Helpers

    /// Returns only the non-standard components from a payslip dictionary.
    /// Standard fields are excluded because they are already surfaced through
    /// dedicated properties (credits, debits, dsop, tax, etc.).
    func extractBreakdownFromPayslip(_ dict: [String: Double]) -> [String: Double] {
        let standardFields: Set<String> = [
            "Basic Pay",
            "Dearness Allowance",
            "Military Service Pay",
            "Other Earnings",
            "DSOP",
            "AGIF",
            "Income Tax",
            "Other Deductions"
        ]
        return dict.filter { !standardFields.contains($0.key) }
    }
}
