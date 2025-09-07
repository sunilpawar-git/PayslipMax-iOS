import SwiftUI
import Charts

/// Financial overview section component for InsightsView
struct InsightsFinancialOverviewSection: View {
    @ObservedObject var coordinator: InsightsCoordinator
    let filteredPayslips: [PayslipItem]
    let selectedTimeRange: FinancialTimeRange

    private var chartSubtitleForTimeRange: String {
        switch selectedTimeRange {
        case .last3Months:
            return "3-month trend"
        case .last6Months:
            return "6-month trend"
        case .lastYear:
            return "Annual trend"
        case .all:
            return "Complete history"
        }
    }

    private var chartHeightForTimeRange: CGFloat {
        switch selectedTimeRange {
        case .last3Months:
            return 55
        case .last6Months:
            return 60
        case .lastYear:
            return 70
        case .all:
            return 80
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with metadata
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Financial Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(FintechColors.textPrimary)

                    Text("Analyzed \(filteredPayslips.count) payslip\(filteredPayslips.count != 1 ? "s" : "") (\(selectedTimeRange.displayName))")
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last Updated")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)

                    Text(coordinator.financialSummary.lastUpdated)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                }
            }

            // Financial metrics in compact layout
            VStack(spacing: 12) {
                // Total Credits
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundColor(FintechColors.successGreen)
                            .font(.title3)

                        Text("Total Credits")
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                    }

                    Spacer()

                    Text("₹\(Formatters.formatIndianCurrency(coordinator.financialSummary.totalIncome))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                }

                // Total Deductions
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.right.circle.fill")
                            .foregroundColor(FintechColors.dangerRed)
                            .font(.title3)

                        Text("Total Deductions")
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                    }

                    Spacer()

                    Text("₹\(Formatters.formatIndianCurrency(coordinator.financialSummary.totalDeductions))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                }
            }

            // Divider between basic metrics and trend analysis
            Divider()
                .background(FintechColors.divider.opacity(0.3))

            // Enhanced trend analysis section
            VStack(spacing: 16) {
                // Net & Average remittance with trend
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Net Remittance")
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)

                        HStack(spacing: 8) {
                            Text("₹\(Formatters.formatIndianCurrency(coordinator.financialSummary.netIncome))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(FintechColors.getAccessibleColor(for: coordinator.financialSummary.netIncome, isPositive: coordinator.financialSummary.netIncome >= 0))

                            // Add trend indicator here if available from ViewModel
                            if coordinator.financialSummary.netIncomeTrend != 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: coordinator.financialSummary.netIncomeTrend > 0 ? "arrow.up" : "arrow.down")
                                        .font(.caption)
                                        .foregroundColor(coordinator.financialSummary.netIncomeTrend > 0 ? FintechColors.successGreen : FintechColors.dangerRed)
                                }
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Average Remittance")
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)

                        Text("₹\(Formatters.formatIndianCurrency(coordinator.financialSummary.averageNetRemittance))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                    }
                }

                // Chart subtitle and period info
                HStack {
                    Text(chartSubtitleForTimeRange)
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    Spacer()
                    Text("\(filteredPayslips.count) months")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }

                // Trend chart - using the existing FinancialOverviewCard's chart component
                if !filteredPayslips.isEmpty {
                    TrendLineView(data: filteredPayslips, timeRange: selectedTimeRange)
                        .frame(height: chartHeightForTimeRange)
                        .id("TrendLineView-\(selectedTimeRange)-\(filteredPayslips.count)")
                } else {
                    // Empty state
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(FintechColors.textSecondary.opacity(0.5))
                            Text("No payslips in this period")
                                .font(.caption)
                                .foregroundColor(FintechColors.textSecondary)
                        }
                        .frame(height: 60)
                    }
                }

                // Quick breakdown cards at bottom
                HStack(spacing: 12) {
                    QuickStatCard(
                        title: "Credits",
                        value: coordinator.financialSummary.totalIncome,
                        color: FintechColors.successGreen
                    )

                    QuickStatCard(
                        title: "Debits",
                        value: coordinator.financialSummary.totalDeductions,
                        color: FintechColors.dangerRed
                    )
                }
            }
        }
        .fintechCardStyle()
    }
}

// MARK: - Supporting Components

private struct QuickStatCard: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)

            Text("₹\(Formatters.formatIndianCurrency(value))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}
