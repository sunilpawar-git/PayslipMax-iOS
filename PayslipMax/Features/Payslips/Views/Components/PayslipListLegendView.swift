import SwiftUI

/// Inline legend explaining X-Ray tints in the payslip list.
struct XRayLegendRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LegendSwatch(color: FintechColors.xRayPositiveAccent, text: "Higher net vs previous month")
            LegendSwatch(color: FintechColors.xRayNegativeAccent, text: "Lower net vs previous month")
            LegendSwatch(color: FintechColors.textSecondary.opacity(0.6), text: "No change vs previous month")

            Divider().opacity(0.35)

            LegendArrow(icon: "arrow.up", color: FintechColors.successGreen, text: "Amount increased from previous month")
            LegendArrow(icon: "arrow.down", color: FintechColors.dangerRed, text: "Amount decreased from previous month")
            LegendArrow(icon: "arrow.left", color: FintechColors.textSecondary, text: "New earning added this month")
            LegendArrow(icon: "arrow.right", color: FintechColors.textSecondary, text: "New deduction added this month")
            LegendArrow(icon: "minus", color: FintechColors.textTertiary, text: "Amount unchanged from previous month")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.footnote)
        .foregroundColor(FintechColors.textSecondary)
        .padding(12)
        .background(FintechColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("X-Ray highlights legend")
    }
}

private struct LegendSwatch: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .padding(.top, 2)
            Text(text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct LegendArrow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .padding(.top, 2)
            Text(text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

