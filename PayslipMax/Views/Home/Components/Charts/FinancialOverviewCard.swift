//
//  FinancialOverviewCard.swift
//  PayslipMax
//
//  Created by GlobalDataTech on 2024
//  Architecture: MVVM-SOLID compliant financial overview component
//  Lines: ~130 (well under 300-line limit - component extraction completed)

import SwiftUI
import Charts

/// Main financial overview card that displays key financial metrics and trends
/// Architecture: MVVM compliant, uses dependency injection, single responsibility
struct FinancialOverviewCard: View {
    let payslips: [PayslipItem]
    @Binding var selectedTimeRange: FinancialTimeRange
    let useExternalFiltering: Bool

    // Architecture: Dependency injection for data processing
    private let dataProcessor: FinancialDataProcessorProtocol

    // New initializer that accepts external time range
    init(payslips: [PayslipItem],
         selectedTimeRange: Binding<FinancialTimeRange>,
         useExternalFiltering: Bool = true,
         dataProcessor: FinancialDataProcessorProtocol = FinancialDataProcessor()) {
        self.payslips = payslips
        self._selectedTimeRange = selectedTimeRange
        self.useExternalFiltering = useExternalFiltering
        self.dataProcessor = dataProcessor
    }

    // Legacy initializer for backward compatibility (keeps internal state)
    init(payslips: [PayslipItem]) {
        self.payslips = payslips
        self._selectedTimeRange = .constant(.last6Months)
        self.useExternalFiltering = false
        self.dataProcessor = FinancialDataProcessor()
    }

    // Architecture: Computed properties delegate to data processor
    private var filteredData: [PayslipItem] {
        dataProcessor.filterPayslips(payslips, for: selectedTimeRange)
    }

    private var totalNet: Double {
        dataProcessor.calculateTotalNet(filteredData)
    }

    private var averageMonthly: Double {
        dataProcessor.calculateAverageMonthly(filteredData)
    }

    private var trendDirection: TrendDirection {
        dataProcessor.calculateTrendDirection(filteredData)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with time range selector (only when not using external filtering)
            HStack {
                Text("Financial Overview")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                if !useExternalFiltering {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(FinancialTimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }
            
            // Main summary section
            VStack(spacing: 12) {
                // Net worth display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Net Remittance")
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                        
                        HStack(spacing: 8) {
                            Text("₹\(Formatters.formatIndianCurrency(totalNet))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(FintechColors.getAccessibleColor(for: totalNet, isPositive: totalNet >= 0))
                            
                            TrendIndicator(direction: trendDirection)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Average Remittance")
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                        
                        Text("₹\(Formatters.formatIndianCurrency(averageMonthly))")
                            .font(.headline)
                            .foregroundColor(FintechColors.textPrimary)
                    }
                }
                
                // Simplified trend line
                if !filteredData.isEmpty {
                    VStack(spacing: 8) {
                        // Add a subtitle for the chart based on time range
                        HStack {
                            Text(selectedTimeRange.chartSubtitle)
                                .font(.caption)
                                .foregroundColor(FintechColors.textSecondary)
                            Spacer()
                            Text("\(filteredData.count) months")
                                .font(.caption)
                                .foregroundColor(FintechColors.textSecondary)
                        }

                        TrendLineView(data: filteredData, timeRange: selectedTimeRange)
                            .frame(height: selectedTimeRange.chartHeight)
                            .id("TrendLineView-\(selectedTimeRange)-\(filteredData.count)") // Force refresh when range or data changes
                    }
                } else {
                    // Enhanced empty state
                    VStack(spacing: 8) {
                        HStack {
                            Text("No data for \(selectedTimeRange.fullDisplayName)")
                                .font(.caption)
                                .foregroundColor(FintechColors.textSecondary)
                            Spacer()
                        }
                        
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
                
                // Quick stats row
                HStack(spacing: 16) {
                    QuickStatCard(
                        title: "Total Credits",
                        value: filteredData.reduce(0) { $0 + $1.credits },
                        color: FintechColors.successGreen
                    )
                    
                    QuickStatCard(
                        title: "Total Debits", 
                        value: filteredData.reduce(0) { $0 + $1.debits },
                        color: FintechColors.dangerRed
                    )
                }
            }
        }
        .fintechCardStyle()
        .animation(.easeInOut(duration: 0.3), value: selectedTimeRange) // Add animation for smooth transitions
    }
} 