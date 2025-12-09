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
        let sortedPayslips = allPayslips.sorted(by: sortChronologically)

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
    private func monthToNumber(_ month: String) -> Int? {
        let normalized = month.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let lookup: [String: Int] = [
            "january": 1, "jan": 1,
            "february": 2, "feb": 2,
            "march": 3, "mar": 3,
            "april": 4, "apr": 4,
            "may": 5,
            "june": 6, "jun": 6,
            "july": 7, "jul": 7,
            "august": 8, "aug": 8,
            "september": 9, "sep": 9, "sept": 9,
            "october": 10, "oct": 10,
            "november": 11, "nov": 11,
            "december": 12, "dec": 12
        ]

        if let value = lookup[normalized] {
            return value
        }

        if let numeric = Int(normalized), (1...12).contains(numeric) {
            return numeric
        }

        Logger.warning("Failed to parse month: '\(month)'", category: "PayslipComparisonService")
        return nil
    }

    private func sortChronologically(lhs: AnyPayslip, rhs: AnyPayslip) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }

        let lhsMonth = monthValue(for: lhs)
        let rhsMonth = monthValue(for: rhs)

        if lhsMonth != rhsMonth {
            return lhsMonth < rhsMonth
        }

        if lhs.timestamp != rhs.timestamp {
            return lhs.timestamp < rhs.timestamp
        }

        return lhs.id.uuidString < rhs.id.uuidString
    }

    private func monthValue(for payslip: AnyPayslip) -> Int {
        if let parsedMonth = monthToNumber(payslip.month) {
            return parsedMonth
        }

        // Fallback to timestamp when month strings are malformed
        return Calendar.current.component(.month, from: payslip.timestamp)
    }
}
