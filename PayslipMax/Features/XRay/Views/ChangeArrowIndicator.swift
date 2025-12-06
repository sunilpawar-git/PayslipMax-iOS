//
//  ChangeArrowIndicator.swift
//  PayslipMax
//
//  Created by Claude Code on 12/6/24.
//

import SwiftUI

/// Arrow indicator showing direction of change for payslip line items
/// - Green up arrow: Amount increased
/// - Red down arrow: Amount decreased
/// - Grey left arrow: New earning (not in previous month)
/// - Grey right arrow: New deduction (not in previous month)
/// - Grey minus: Unchanged amount
struct ChangeArrowIndicator: View {
    let direction: ChangeDirection
    let isEarning: Bool

    var body: some View {
        Image(systemName: arrowIcon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(arrowColor)
            .accessibilityLabel(accessibilityText)
    }

    private var arrowIcon: String {
        switch direction {
        case .increased:
            return "arrow.up"
        case .decreased:
            return "arrow.down"
        case .new:
            // Inward arrow for earnings (←), outward arrow for deductions (→)
            return isEarning ? "arrow.left" : "arrow.right"
        case .unchanged:
            return "minus"
        }
    }

    private var arrowColor: Color {
        switch direction {
        case .increased:
            return FintechColors.successGreen
        case .decreased:
            return FintechColors.dangerRed
        case .new:
            return FintechColors.textSecondary
        case .unchanged:
            return FintechColors.textTertiary
        }
    }

    private var accessibilityText: String {
        switch direction {
        case .increased:
            return "Amount increased"
        case .decreased:
            return "Amount decreased"
        case .new:
            return isEarning ? "New earning" : "New deduction"
        case .unchanged:
            return "Amount unchanged"
        }
    }
}

// MARK: - Previews
#Preview("All Directions - Earnings") {
    VStack(alignment: .leading, spacing: 16) {
        HStack {
            ChangeArrowIndicator(direction: .increased, isEarning: true)
            Text("Increased")
        }
        HStack {
            ChangeArrowIndicator(direction: .decreased, isEarning: true)
            Text("Decreased")
        }
        HStack {
            ChangeArrowIndicator(direction: .new, isEarning: true)
            Text("New Earning (←)")
        }
        HStack {
            ChangeArrowIndicator(direction: .unchanged, isEarning: true)
            Text("Unchanged")
        }
    }
    .padding()
}

#Preview("All Directions - Deductions") {
    VStack(alignment: .leading, spacing: 16) {
        HStack {
            ChangeArrowIndicator(direction: .increased, isEarning: false)
            Text("Increased")
        }
        HStack {
            ChangeArrowIndicator(direction: .decreased, isEarning: false)
            Text("Decreased")
        }
        HStack {
            ChangeArrowIndicator(direction: .new, isEarning: false)
            Text("New Deduction (→)")
        }
        HStack {
            ChangeArrowIndicator(direction: .unchanged, isEarning: false)
            Text("Unchanged")
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(alignment: .leading, spacing: 16) {
        HStack {
            ChangeArrowIndicator(direction: .increased, isEarning: true)
            Text("Increased")
        }
        HStack {
            ChangeArrowIndicator(direction: .decreased, isEarning: true)
            Text("Decreased")
        }
        HStack {
            ChangeArrowIndicator(direction: .new, isEarning: true)
            Text("New")
        }
        HStack {
            ChangeArrowIndicator(direction: .unchanged, isEarning: true)
            Text("Unchanged")
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}
