import SwiftUI
import Charts

// Define PayslipChartData here instead of importing it
struct PayslipChartData: Identifiable, Equatable, Hashable {
    let id = UUID()
    let month: String
    let credits: Double
    let debits: Double
    let net: Double

    static func == (lhs: PayslipChartData, rhs: PayslipChartData) -> Bool {
        return lhs.month == rhs.month &&
               lhs.credits == rhs.credits &&
               lhs.debits == rhs.debits &&
               lhs.net == rhs.net
    }
}

/// A view for displaying financial charts
struct ChartsView: View {
    let data: [PayslipChartData]
    let payslips: [AnyPayslip] // Add payslips parameter for the FinancialOverviewCard
    @Environment(\.tabSelection) private var tabSelection

    var body: some View {
        // Simple summary card that encourages users to go to Insights
        VStack {
            if !payslips.isEmpty {
                // Quick summary card with navigation to Insights
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Financial Summary")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(FintechColors.textPrimary)

                            Text("\(payslips.count) payslip\(payslips.count != 1 ? "s" : "") processed")
                                .font(.subheadline)
                                .foregroundColor(FintechColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(FintechColors.primaryBlue)
                    }

                    // Quick stats
                    HStack(spacing: 16) {
                        QuickSummaryCard(
                            title: "Total Income",
                            value: totalIncome,
                            color: FintechColors.successGreen
                        )

                        QuickSummaryCard(
                            title: "Net Amount",
                            value: netAmount,
                            color: FintechColors.primaryBlue
                        )
                    }

                    // Call to action
                    HStack {
                        Text("View detailed charts and analysis")
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("Go to Insights")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(FintechColors.primaryBlue)

                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(FintechColors.primaryBlue)
                        }
                    }
                    .padding(.top, 8)
                }
                .fintechCardStyle()
                .onTapGesture {
                    // Navigate to Insights tab (index 2)
                    tabSelection.wrappedValue = 2
                }
                .accessibilityIdentifier("financial_summary_card")
                .accessibilityLabel("Financial Summary. Tap to view detailed insights.")
            } else {
                // Show empty state when no payslips are available
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Financial Data")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Upload your first payslip to see financial insights")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
        }
    }

    private var totalIncome: Double {
        payslips.reduce(0) { $0 + $1.credits }
    }

    private var netAmount: Double {
        payslips.reduce(0) { $0 + ($1.credits - $1.debits) }
    }
}

struct QuickSummaryCard: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)

            Text("₹\(formatCurrency(value))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// Helper struct for equatable comparison
struct ChartsContent: Equatable {
    let data: [PayslipChartData]

    static func == (lhs: ChartsContent, rhs: ChartsContent) -> Bool {
        guard lhs.data.count == rhs.data.count else { return false }

        for (index, lhsItem) in lhs.data.enumerated() {
            let rhsItem = rhs.data[index]
            if lhsItem != rhsItem {
                return false
            }
        }

        return true
    }
}

#Preview {
    ChartsView(
        data: [
            PayslipChartData(month: "Jan", credits: 50000, debits: 30000, net: 20000),
            PayslipChartData(month: "Feb", credits: 60000, debits: 35000, net: 25000),
            PayslipChartData(month: "Mar", credits: 55000, debits: 32000, net: 23000)
        ],
        payslips: []
    )
}
