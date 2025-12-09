import Foundation

// MARK: - Payslip Comparison

/// Represents a comparison between two payslips (current vs previous month)
struct PayslipComparison: Identifiable, Equatable {
    let id: UUID
    let currentPayslip: AnyPayslip
    let previousPayslip: AnyPayslip?

    // Net remittance comparison
    let netRemittanceChange: Double
    let netRemittancePercentageChange: Double?

    // Item-level comparisons
    let earningsChanges: [String: ItemComparison]
    let deductionsChanges: [String: ItemComparison]

    init(
        id: UUID = UUID(),
        currentPayslip: AnyPayslip,
        previousPayslip: AnyPayslip?,
        netRemittanceChange: Double,
        netRemittancePercentageChange: Double?,
        earningsChanges: [String: ItemComparison],
        deductionsChanges: [String: ItemComparison]
    ) {
        self.id = id
        self.currentPayslip = currentPayslip
        self.previousPayslip = previousPayslip
        self.netRemittanceChange = netRemittanceChange
        self.netRemittancePercentageChange = netRemittancePercentageChange
        self.earningsChanges = earningsChanges
        self.deductionsChanges = deductionsChanges
    }

    /// Returns true if net remittance increased compared to previous month
    var hasIncreasedNetRemittance: Bool {
        netRemittanceChange > 0
    }

    /// Returns true if net remittance decreased compared to previous month
    var hasDecreasedNetRemittance: Bool {
        netRemittanceChange < 0
    }

    /// Returns true if there's a previous payslip to compare against
    var hasPreviousPayslip: Bool {
        previousPayslip != nil
    }

    static func == (lhs: PayslipComparison, rhs: PayslipComparison) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Item Comparison

/// Represents comparison data for an individual earning or deduction item
struct ItemComparison: Identifiable, Equatable {
    let id: UUID
    let itemName: String
    let currentAmount: Double
    let previousAmount: Double?
    let absoluteChange: Double
    let percentageChange: Double?
    let needsAttention: Bool

    init(
        id: UUID = UUID(),
        itemName: String,
        currentAmount: Double,
        previousAmount: Double?,
        absoluteChange: Double,
        percentageChange: Double?,
        needsAttention: Bool
    ) {
        self.id = id
        self.itemName = itemName
        self.currentAmount = currentAmount
        self.previousAmount = previousAmount
        self.absoluteChange = absoluteChange
        self.percentageChange = percentageChange
        self.needsAttention = needsAttention
    }

    /// Returns true if this is a new item (not in previous payslip)
    var isNew: Bool {
        previousAmount == nil
    }

    /// Returns true if amount increased compared to previous month
    var hasIncreased: Bool {
        absoluteChange > 0
    }

    /// Returns true if amount decreased compared to previous month
    var hasDecreased: Bool {
        absoluteChange < 0
    }

    /// Returns true if amount is unchanged
    var isUnchanged: Bool {
        absoluteChange == 0 && previousAmount != nil
    }

    static func == (lhs: ItemComparison, rhs: ItemComparison) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Change Direction

/// Direction of change for visual indicators
enum ChangeDirection: String, CaseIterable {
    case increased  // Green up arrow
    case decreased  // Red down arrow
    case new        // Grey arrow (inward for earnings, outward for deductions)
    case unchanged  // No indicator or minus sign

    /// Returns the appropriate ChangeDirection for an ItemComparison
    /// - Parameter itemComparison: The item comparison to evaluate
    /// - Returns: The change direction
    static func from(_ itemComparison: ItemComparison) -> ChangeDirection {
        if itemComparison.isNew {
            return .new
        } else if itemComparison.hasIncreased {
            return .increased
        } else if itemComparison.hasDecreased {
            return .decreased
        } else {
            return .unchanged
        }
    }
}
