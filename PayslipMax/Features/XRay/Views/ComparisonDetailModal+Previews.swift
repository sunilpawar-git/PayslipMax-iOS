import SwiftUI

// MARK: - Previews

#Preview("Decreased Earning - Needs Attention") {
    ComparisonDetailModal(
        itemComparison: ItemComparison(
            itemName: "Basic Pay",
            currentAmount: 45000,
            previousAmount: 50000,
            absoluteChange: -5000,
            percentageChange: -10.0,
            needsAttention: true
        ),
        isEarning: true
    )
}

#Preview("Increased Deduction - Needs Attention") {
    ComparisonDetailModal(
        itemComparison: ItemComparison(
            itemName: "Income Tax",
            currentAmount: 12000,
            previousAmount: 10000,
            absoluteChange: 2000,
            percentageChange: 20.0,
            needsAttention: true
        ),
        isEarning: false
    )
}

#Preview("New Earning") {
    ComparisonDetailModal(
        itemComparison: ItemComparison(
            itemName: "Performance Bonus",
            currentAmount: 15000,
            previousAmount: nil,
            absoluteChange: 15000,
            percentageChange: nil,
            needsAttention: false
        ),
        isEarning: true
    )
}

#Preview("Increased Earning - Positive") {
    ComparisonDetailModal(
        itemComparison: ItemComparison(
            itemName: "Basic Pay",
            currentAmount: 55000,
            previousAmount: 50000,
            absoluteChange: 5000,
            percentageChange: 10.0,
            needsAttention: false
        ),
        isEarning: true
    )
}

#Preview("Dark Mode") {
    ComparisonDetailModal(
        itemComparison: ItemComparison(
            itemName: "Basic Pay",
            currentAmount: 45000,
            previousAmount: 50000,
            absoluteChange: -5000,
            percentageChange: -10.0,
            needsAttention: true
        ),
        isEarning: true
    )
    .preferredColorScheme(.dark)
}
