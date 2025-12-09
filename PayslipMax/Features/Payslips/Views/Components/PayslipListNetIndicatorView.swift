import SwiftUI

/// Compact indicator showing net direction with accessible tooltip.
struct PayslipNetIndicatorView: View {
    let netAmount: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(iconColor)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint("Indicates month-over-month net direction")

            Text(label)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)
        }
    }

    private var iconName: String {
        if netAmount > 0 { return "arrow.up.right" }
        if netAmount < 0 { return "arrow.down.right" }
        return "minus"
    }

    private var label: String {
        if netAmount > 0 { return "Credit" }
        if netAmount < 0 { return "Debit" }
        return "No change"
    }

    private var iconColor: Color {
        if netAmount > 0 { return FintechColors.successGreen }
        if netAmount < 0 { return FintechColors.dangerRed }
        return FintechColors.textSecondary
    }

    private var accessibilityLabel: String {
        if netAmount > 0 { return "Up arrow: net remittance is positive" }
        if netAmount < 0 { return "Down arrow: net remittance is negative" }
        return "Dash: net remittance is unchanged"
    }
}

