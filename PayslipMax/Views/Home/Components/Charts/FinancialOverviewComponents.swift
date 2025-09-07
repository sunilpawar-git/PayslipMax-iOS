//
//  FinancialOverviewComponents.swift
//  PayslipMax
//
//  Created by GlobalDataTech on 2024
//  Architecture: MVVM-SOLID compliant UI components
//  Lines: ~145 (well under 300-line limit)

import SwiftUI
import Charts

/// Small indicator showing trend direction for financial metrics
/// Architecture: Single responsibility - display only, no business logic
struct TrendIndicator: View {
    let direction: TrendDirection

    var body: some View {
        Group {
            switch direction {
            case .up:
                Image(systemName: "arrow.up.right")
                    .foregroundColor(FintechColors.successGreen)
            case .down:
                Image(systemName: "arrow.down.right")
                    .foregroundColor(FintechColors.dangerRed)
            case .neutral:
                Image(systemName: "minus")
                    .foregroundColor(FintechColors.warningAmber)
            }
        }
        .font(.caption)
    }
}

/// Compact card displaying key financial statistics
/// Architecture: Pure UI component with injected data, no calculations
struct QuickStatCard: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)

            Text("₹\(Formatters.formatIndianCurrency(value))")
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
}

/// Advanced chart view for displaying financial trend lines
/// Architecture: Complex UI component with chart rendering logic
struct TrendLineView: View {
    let data: [PayslipItem]
    let timeRange: FinancialTimeRange

    private var chartData: [(index: Int, value: Double, date: String)] {
        return data.enumerated().map { index, item in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let monthLabel = formatter.string(from: item.timestamp)
            return (index: index, value: item.credits - item.debits, date: monthLabel)
        }
    }

    private var averageValue: Double {
        // Use the same calculation method as FinancialCalculationUtility
        guard !data.isEmpty else { return 0 }
        let totalNetIncome = data.reduce(0) { result, payslip in
            result + (payslip.credits - payslip.debits)
        }
        return totalNetIncome / Double(data.count)
    }

    private var lineStyle: StrokeStyle {
        switch timeRange {
        case .last3Months:
            return StrokeStyle(lineWidth: 3.5, lineCap: .round) // Thickest for least data
        case .last6Months:
            return StrokeStyle(lineWidth: 3, lineCap: .round) // Thicker for less data
        case .lastYear:
            return StrokeStyle(lineWidth: 2.5, lineCap: .round)
        case .all:
            return StrokeStyle(lineWidth: 2, lineCap: .round) // Thinner for more data
        }
    }

    private var symbolSize: CGFloat {
        switch timeRange {
        case .last3Months:
            return 45 // Largest symbols for fewest points
        case .last6Months:
            return 40 // Larger symbols for fewer points
        case .lastYear:
            return 30
        case .all:
            return 25 // Smaller symbols for more dense data
        }
    }

    private var showDataPoints: Bool {
        switch timeRange {
        case .last3Months:
            return true // Always show points for 3M
        case .last6Months:
            return true // Always show points for 6M
        case .lastYear:
            return data.count <= 12 // Show points if 12 or fewer
        case .all:
            return data.count <= 8 // Only show points if very sparse data
        }
    }

    var body: some View {
        Group {
            if data.isEmpty {
                // Show empty state
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(FintechColors.textSecondary)
                    Text("No data available")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if data.count == 1 {
                // Show single point as a dot with label
                VStack(spacing: 4) {
                    Circle()
                        .fill(FintechColors.chartPrimary)
                        .frame(width: 8, height: 8)
                    Text("₹\(Formatters.formatIndianCurrency(data.first!.credits - data.first!.debits))")
                        .font(.caption2)
                        .foregroundColor(FintechColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Show full chart with time-range specific styling
                ZStack {
                    Chart {
                        ForEach(chartData, id: \.index) { dataPoint in
                            LineMark(
                                x: .value("Period", dataPoint.index),
                                y: .value("Net", dataPoint.value)
                            )
                            .foregroundStyle(FintechColors.primaryGradient)
                            .lineStyle(lineStyle)

                            AreaMark(
                                x: .value("Period", dataPoint.index),
                                y: .value("Net", dataPoint.value)
                            )
                            .foregroundStyle(FintechColors.chartAreaGradient)

                            // Conditionally add point markers
                            if showDataPoints {
                                PointMark(
                                    x: .value("Period", dataPoint.index),
                                    y: .value("Net", dataPoint.value)
                                )
                                .foregroundStyle(FintechColors.chartPrimary)
                                .symbolSize(symbolSize)
                            }
                        }

                        // Add average line
                        RuleMark(
                            y: .value("Average", averageValue)
                        )
                        .foregroundStyle(FintechColors.textSecondary.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartYScale(domain: .automatic(includesZero: false))
                    .animation(.easeInOut(duration: 0.5), value: timeRange) // Smooth transitions

                    // Average value label overlay
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            Text("₹\(Formatters.formatIndianCurrency(averageValue))")
                                .font(.caption2)
                                .foregroundColor(FintechColors.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(FintechColors.textSecondary.opacity(0.1))
                                )
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}
