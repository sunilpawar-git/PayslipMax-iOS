import Foundation

// MARK: - Protocol

/// Protocol for payslip comparison operations
protocol PayslipComparisonServiceProtocol {
    /// Finds the chronologically previous payslip for a given payslip
    /// - Parameters:
    ///   - payslip: The payslip to find the previous payslip for
    ///   - allPayslips: All available payslips
    /// - Returns: The previous payslip, or nil if this is the first payslip
    func findPreviousPayslip(for payslip: AnyPayslip, in allPayslips: [AnyPayslip]) -> AnyPayslip?

    /// Compares two payslips and returns detailed comparison data
    /// - Parameters:
    ///   - current: The current payslip
    ///   - previous: The previous payslip (can be nil)
    /// - Returns: PayslipComparison containing all comparison data
    func comparePayslips(current: AnyPayslip, previous: AnyPayslip?) -> PayslipComparison

    /// Compares an individual earnings or deduction item
    /// - Parameters:
    ///   - name: The name of the item
    ///   - current: Current amount
    ///   - previous: Previous amount (nil if new item)
    ///   - isEarning: True if this is an earning, false if deduction
    /// - Returns: ItemComparison with change details
    func compareItem(name: String, current: Double, previous: Double?, isEarning: Bool) -> ItemComparison
}

// MARK: - Implementation

/// Service for comparing payslips and calculating month-to-month changes
final class PayslipComparisonService: PayslipComparisonServiceProtocol {

    // MARK: - Find Previous Payslip

    func findPreviousPayslip(for payslip: AnyPayslip, in allPayslips: [AnyPayslip]) -> AnyPayslip? {
        // Sort payslips chronologically (oldest first)
        let sortedPayslips = allPayslips.sorted { lhs, rhs in
            if lhs.year != rhs.year {
                return lhs.year < rhs.year
            }
            return monthToNumber(lhs.month) < monthToNumber(rhs.month)
        }

        // Find current payslip index
        guard let currentIndex = sortedPayslips.firstIndex(where: { $0.id == payslip.id }) else {
            return nil
        }

        // Return previous payslip if exists
        if currentIndex > 0 {
            return sortedPayslips[currentIndex - 1]
        }

        return nil
    }

    // MARK: - Compare Payslips

    func comparePayslips(current: AnyPayslip, previous: AnyPayslip?) -> PayslipComparison {
        // Calculate net remittance for both payslips
        let currentNet = current.credits - current.debits
        let previousNet = previous.map { $0.credits - $0.debits } ?? currentNet

        // Calculate net remittance changes
        let netChange = currentNet - previousNet
        let netPercentChange: Double? = if previous != nil, previousNet != 0 {
            (netChange / previousNet) * 100
        } else {
            nil
        }

        // Compare earnings items
        let earningsChanges = compareItems(
            current: current.earnings,
            previous: previous?.earnings ?? [:],
            isEarning: true
        )

        // Compare deduction items
        let deductionsChanges = compareItems(
            current: current.deductions,
            previous: previous?.deductions ?? [:],
            isEarning: false
        )

        return PayslipComparison(
            currentPayslip: current,
            previousPayslip: previous,
            netRemittanceChange: netChange,
            netRemittancePercentageChange: netPercentChange,
            earningsChanges: earningsChanges,
            deductionsChanges: deductionsChanges
        )
    }

    // MARK: - Compare Item

    func compareItem(name: String, current: Double, previous: Double?, isEarning: Bool) -> ItemComparison {
        let prevAmount = previous ?? 0
        let change = current - prevAmount

        // Calculate percentage change if previous value exists and is non-zero
        let percentChange: Double? = if let previous = previous, previous != 0 {
            (change / previous) * 100
        } else {
            nil
        }

        // Determine if this item needs attention:
        // - Earnings that decreased (bad for user)
        // - Deductions that increased (bad for user)
        let needsAttention: Bool
        if isEarning {
            // For earnings: decrease needs attention
            needsAttention = change < 0 && previous != nil
        } else {
            // For deductions: increase needs attention
            needsAttention = change > 0 && previous != nil
        }

        return ItemComparison(
            itemName: name,
            currentAmount: current,
            previousAmount: previous,
            absoluteChange: change,
            percentageChange: percentChange,
            needsAttention: needsAttention
        )
    }

    // MARK: - Private Helpers

    /// Compares all items in current and previous dictionaries
    private func compareItems(
        current: [String: Double],
        previous: [String: Double],
        isEarning: Bool
    ) -> [String: ItemComparison] {
        var changes: [String: ItemComparison] = [:]

        // Get all unique item names from both current and previous
        let allItems = Set(current.keys).union(Set(previous.keys))

        for itemName in allItems {
            let currentAmount = current[itemName] ?? 0
            let previousAmount = previous[itemName]

            changes[itemName] = compareItem(
                name: itemName,
                current: currentAmount,
                previous: previousAmount,
                isEarning: isEarning
            )
        }

        return changes
    }

    /// Converts month name to number (1-12) for sorting
    private func monthToNumber(_ month: String) -> Int {
        // Try full month name (handles case automatically)
        if let date = parseMonth(month, format: "MMMM") {
            return Calendar.current.component(.month, from: date)
        }

        // Try abbreviated month name
        if let date = parseMonth(month, format: "MMM") {
            return Calendar.current.component(.month, from: date)
        }

        Logger.warning("Failed to parse month: '\(month)'", category: "PayslipComparisonService")
        return 0
    }

    /// Parses a month string using a specific date format
    private func parseMonth(_ month: String, format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter.date(from: month.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
