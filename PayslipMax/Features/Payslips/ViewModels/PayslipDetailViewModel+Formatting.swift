import Foundation

// MARK: - PayslipDetailViewModel: Formatting

/// Formatting and breakdown computed properties, delegated to the
/// injected `PayslipDetailFormatterService`.
/// Keeping these in a dedicated file upholds SRP: the coordinator class
/// owns lifecycle while this extension owns presentation formatting.
extension PayslipDetailViewModel {

    // MARK: - Currency and Date Formatting

    func formatCurrency(_ value: Double?) -> String {
        formatterService.formatCurrency(value)
    }

    func formatYear(_ year: Int) -> String {
        formatterService.formatYear(year)
    }

    func getShareText() -> String {
        formatterService.getShareText(for: payslipData)
    }

    // MARK: - Earnings / Deductions Breakdown

    var earningsBreakdown: [BreakdownItem] {
        formatterService.getEarningsBreakdown(from: payslipData)
    }

    var deductionsBreakdown: [BreakdownItem] {
        formatterService.getDeductionsBreakdown(from: payslipData)
    }
}
