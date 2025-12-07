//
//  ComparisonDetailModal.swift
//  PayslipMax
//
//  Created by Claude Code on 12/6/24.
//

import SwiftUI

/// Modal sheet displaying detailed comparison between current and previous month amounts
/// Shows previous/current amounts, absolute change, and percentage change with color coding
struct ComparisonDetailModal: View {
    @Environment(\.dismiss) private var dismiss

    let itemComparison: ItemComparison
    let isEarning: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header with icon
                headerView

                // Comparison details
                VStack(spacing: 16) {
                    // Previous month amount
                    comparisonRow(
                        label: "Previous Month",
                        amount: itemComparison.previousAmount,
                        color: FintechColors.textSecondary
                    )

                    // Divider
                    FintechDivider()

                    // Current month amount
                    comparisonRow(
                        label: "Current Month",
                        amount: itemComparison.currentAmount,
                        color: FintechColors.textPrimary
                    )

                    // Divider
                    FintechDivider()

                    // Change indicator
                    changeRow
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(FintechColors.cardBackground)
                )

                // Explanation text
                explanationText

                Spacer()
            }
            .padding()
            .navigationTitle(itemComparison.itemName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: isEarning ? "banknote.fill" : "creditcard.fill")
                .font(.system(size: 40))
                .foregroundColor(changeColor)
                .padding()
                .background(
                    Circle()
                        .fill(changeColor.opacity(0.1))
                )

            Text(changeDirectionText)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(changeColor)
        }
    }

    private func comparisonRow(label: String, amount: Double?, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(FintechColors.textSecondary)

            Spacer()

            if let amount = amount {
                Text("₹\(CurrencyFormatter.format(amount))")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(color)
            } else {
                Text("New Item")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(FintechColors.textTertiary)
                    .italic()
            }
        }
    }

    private var changeRow: some View {
        HStack {
            Text("Change")
                .font(.system(size: 15))
                .foregroundColor(FintechColors.textSecondary)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // Absolute change
                HStack(spacing: 4) {
                    Image(systemName: changeIcon)
                        .font(.system(size: 14, weight: .semibold))
                    Text("₹\(CurrencyFormatter.format(abs(itemComparison.absoluteChange)))")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(changeColor)

                // Percentage change
                if let percentageChange = itemComparison.percentageChange {
                    Text("(\(formatPercentage(percentageChange))%)")
                        .font(.system(size: 14))
                        .foregroundColor(changeColor.opacity(0.8))
                }
            }
        }
    }

    private var explanationText: some View {
        Text(explanationMessage)
            .font(.system(size: 14))
            .foregroundColor(FintechColors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    // MARK: - Computed Properties

    private var changeDirection: ChangeDirection {
        ChangeDirection.from(itemComparison)
    }

    private var changeColor: Color {
        if itemComparison.isNew {
            return FintechColors.textSecondary
        }

        // For earnings: increase is good (green), decrease is bad (red)
        // For deductions: increase is bad (red), decrease is good (green)
        if isEarning {
            return itemComparison.hasIncreased ? FintechColors.successGreen : FintechColors.dangerRed
        } else {
            return itemComparison.hasIncreased ? FintechColors.dangerRed : FintechColors.successGreen
        }
    }

    private var changeIcon: String {
        if itemComparison.isNew {
            return "plus.circle.fill"
        }
        return itemComparison.hasIncreased ? "arrow.up" : "arrow.down"
    }

    private var changeDirectionText: String {
        if itemComparison.isNew {
            return isEarning ? "New Earning" : "New Deduction"
        } else if itemComparison.hasIncreased {
            // Differentiate earnings vs deductions for accessibility/readability
            return isEarning ? "Earning Increased" : "Deduction Increased"
        } else if itemComparison.hasDecreased {
            return isEarning ? "Earning Decreased" : "Deduction Decreased"
        } else {
            return "No Change"
        }
    }

    private var explanationMessage: String {
        if itemComparison.isNew {
            return "This item appears for the first time in the current month's payslip."
        } else if itemComparison.needsAttention {
            if isEarning {
                return "This earning has decreased compared to the previous month. Review your payslip for details."
            } else {
                return "This deduction has increased compared to the previous month. Review your payslip for details."
            }
        } else {
            if isEarning {
                return "This earning has improved compared to the previous month."
            } else {
                return "This deduction has decreased compared to the previous month."
            }
        }
    }

    // MARK: - Helper Methods

    private func formatPercentage(_ value: Double) -> String {
        let absValue = abs(value)
        return String(format: "%.1f", absValue)
    }
}

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
