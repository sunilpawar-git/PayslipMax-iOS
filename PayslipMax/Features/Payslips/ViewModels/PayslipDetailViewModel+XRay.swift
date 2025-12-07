import Foundation

// MARK: - X-Ray Comparison
extension PayslipDetailViewModel: XRaySubscribable {

    func onXRayToggleChanged() {
        guard let payslips = allPayslips else { return }
        computeComparison(with: payslips)
    }

    func computeComparison(with allPayslips: [AnyPayslip]) {
        guard xRaySettings.isXRayEnabled else {
            // Clear comparison if X-Ray is disabled
            self.comparison = nil
            return
        }

        // Check cache first
        if let cached = comparisonCacheManager.getComparison(for: payslip.id) {
            self.comparison = cached
            return
        }

        // Compute and cache
        let previous = comparisonService.findPreviousPayslip(for: payslip, in: allPayslips)
        let comparison = comparisonService.comparePayslips(current: payslip, previous: previous)
        self.comparison = comparison
        comparisonCacheManager.setComparison(comparison, for: payslip.id)
    }

    func invalidateComparisons() {
        comparisonCacheManager.invalidateComparison(for: payslip.id)

        guard let payslips = allPayslips,
              let nextPayslip = findNextPayslip(after: payslip, in: payslips) else {
            return
        }

        comparisonCacheManager.invalidateComparison(for: nextPayslip.id)
    }

    func refreshComparisonsIfNeeded() {
        guard let payslips = allPayslips else { return }
        comparisonCacheManager.waitForPendingOperations()
        computeComparison(with: payslips)
    }

    private func findNextPayslip(after current: AnyPayslip, in payslips: [AnyPayslip]) -> AnyPayslip? {
        let sortedPayslips = payslips.sorted { lhs, rhs in
            if lhs.year != rhs.year {
                return lhs.year < rhs.year
            }
            return convertMonthToNumber(lhs.month) < convertMonthToNumber(rhs.month)
        }

        guard let index = sortedPayslips.firstIndex(where: { $0.id == current.id }) else {
            return nil
        }

        let nextIndex = sortedPayslips.index(after: index)
        return nextIndex < sortedPayslips.count ? sortedPayslips[nextIndex] : nil
    }

    private func convertMonthToNumber(_ month: String) -> Int {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        formatter.dateFormat = "MMMM"
        if let date = formatter.date(from: month) {
            return Calendar.current.component(.month, from: date)
        }

        formatter.dateFormat = "MMM"
        if let date = formatter.date(from: month) {
            return Calendar.current.component(.month, from: date)
        }

        Logger.warning("Failed to parse month: '\(month)'", category: "PayslipDetailViewModel")
        return 0
    }
}

