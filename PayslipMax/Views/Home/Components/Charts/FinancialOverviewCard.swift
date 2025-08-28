import SwiftUI
import Charts

struct FinancialOverviewCard: View {
    let payslips: [PayslipItem]
    @Binding var selectedTimeRange: FinancialTimeRange
    let useExternalFiltering: Bool
    
    // New initializer that accepts external time range
    init(payslips: [PayslipItem], selectedTimeRange: Binding<FinancialTimeRange>, useExternalFiltering: Bool = true) {
        self.payslips = payslips
        self._selectedTimeRange = selectedTimeRange
        self.useExternalFiltering = useExternalFiltering
    }
    
    // Legacy initializer for backward compatibility (keeps internal state)
    init(payslips: [PayslipItem]) {
        self.payslips = payslips
        self._selectedTimeRange = .constant(.last6Months)
        self.useExternalFiltering = false
    }
    
    private var filteredData: [PayslipItem] {
        let sortedPayslips = payslips.sorted { $0.timestamp > $1.timestamp }
        
        // Use the latest payslip's period as the reference point instead of current date
        // This ensures we get the correct count (12 for 1Y, 6 for 6M, 3 for 3M)
        guard let latestPayslip = sortedPayslips.first else {
            print("❌ No payslips available for FinancialOverviewCard")
            return []
        }
        
        let latestPayslipDate = createDateFromPayslip(latestPayslip)
        let calendar = Calendar.current
        
        print("🏠 FinancialOverviewCard filtering: Total payslips: \(payslips.count), Selected range: \(selectedTimeRange)")
        print("📅 Latest payslip period: \(latestPayslip.month) \(latestPayslip.year)")
        
        // Print all payslip timestamps for debugging
        for (index, payslip) in sortedPayslips.enumerated() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            print("Payslip \(index): \(payslip.month) \(payslip.year) - \(formatter.string(from: payslip.timestamp))")
        }
        
        switch selectedTimeRange {
        case .last3Months:
            // Calculate 3 months back from the latest payslip month
            guard let cutoffDate = calendar.date(byAdding: .month, value: -2, to: latestPayslipDate) else {
                print("❌ Failed to calculate 3 month cutoff date")
                return sortedPayslips
            }
            
            let filtered = sortedPayslips.filter { payslip in
                let payslipDate = createDateFromPayslip(payslip)
                let isIncluded = payslipDate >= cutoffDate
                print("  Payslip \(payslip.month) \(payslip.year): \(isIncluded ? "✅ INCLUDED" : "❌ excluded")")
                return isIncluded
            }
            
            print("3M filtered result: \(filtered.count) payslips")
            return filtered
            
        case .last6Months:
            // Calculate 6 months back from the latest payslip month
            guard let cutoffDate = calendar.date(byAdding: .month, value: -5, to: latestPayslipDate) else {
                print("❌ Failed to calculate 6 month cutoff date")
                return sortedPayslips
            }
            
            let filtered = sortedPayslips.filter { payslip in
                let payslipDate = createDateFromPayslip(payslip)
                let isIncluded = payslipDate >= cutoffDate
                print("  Payslip \(payslip.month) \(payslip.year): \(isIncluded ? "✅ INCLUDED" : "❌ excluded")")
                return isIncluded
            }
            
            print("6M filtered result: \(filtered.count) payslips")
            return filtered
            
        case .lastYear:
            // Calculate 12 months back from the latest payslip month
            guard let cutoffDate = calendar.date(byAdding: .month, value: -11, to: latestPayslipDate) else {
                print("❌ Failed to calculate 1 year cutoff date")
                return sortedPayslips
            }
            print("1Y cutoff date: \(cutoffDate)")
            let filtered = sortedPayslips.filter { 
                let payslipDate = createDateFromPayslip($0)
                return payslipDate >= cutoffDate 
            }
            print("1Y filtered result: \(filtered.count) payslips")
            return filtered
            
        case .all:
            print("ALL: returning all \(sortedPayslips.count) payslips")
            return sortedPayslips
        }
    }
    
    /// Creates a Date object from a payslip's period (month/year), not the creation timestamp
    private func createDateFromPayslip(_ payslip: PayslipItem) -> Date {
        let monthInt = monthToInt(payslip.month)
        let year = payslip.year
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = monthInt > 0 ? monthInt : 1 // Default to January if month parsing fails
        dateComponents.day = 1 // Use first day of the month
        
        return Calendar.current.date(from: dateComponents) ?? Date.distantPast
    }
    
    /// Converts a month name to an integer for date calculations
    private func monthToInt(_ month: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        if let date = formatter.date(from: month) {
            return Calendar.current.component(.month, from: date)
        }
        
        // Fallback for short month names
        formatter.dateFormat = "MMM"
        if let date = formatter.date(from: month) {
            return Calendar.current.component(.month, from: date)
        }
        
        // Manual mapping for common cases
        let monthMap = [
            "january": 1, "jan": 1,
            "february": 2, "feb": 2,
            "march": 3, "mar": 3,
            "april": 4, "apr": 4,
            "may": 5,
            "june": 6, "jun": 6,
            "july": 7, "jul": 7,
            "august": 8, "aug": 8,
            "september": 9, "sep": 9, "sept": 9,
            "october": 10, "oct": 10,
            "november": 11, "nov": 11,
            "december": 12, "dec": 12
        ]
        
        return monthMap[month.lowercased()] ?? 0
    }
    
    private var totalNet: Double {
        let net = filteredData.reduce(0) { $0 + ($1.credits - $1.debits) }
        let filterMode = useExternalFiltering ? "EXTERNAL" : "INTERNAL"
        print("💰 Total net for \(selectedTimeRange) (\(filterMode)): ₹\(net) from \(filteredData.count) payslips")
        return net
    }
    
    private var averageMonthly: Double {
        guard !filteredData.isEmpty else { return 0 }
        return totalNet / Double(filteredData.count)
    }
    
    private var trendDirection: ChartTrendDirection {
        guard filteredData.count >= 2 else { return .neutral }
        let recent = Array(filteredData.prefix(3))
        let older = Array(filteredData.dropFirst(3).prefix(3))
        
        let recentAvg = recent.reduce(0) { $0 + ($1.credits - $1.debits) } / Double(recent.count)
        let olderAvg = older.isEmpty ? recentAvg : older.reduce(0) { $0 + ($1.credits - $1.debits) } / Double(older.count)
        
        if recentAvg > olderAvg * 1.05 {
            return .up
        } else if recentAvg < olderAvg * 0.95 {
            return .down
        } else {
            return .neutral
        }
    }
    
    private var chartSubtitle: String {
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
    
    private var chartHeight: CGFloat {
        switch selectedTimeRange {
        case .last3Months:
            return 55 // Very compact for fewer data points
        case .last6Months:
            return 60 // Compact for fewer data points
        case .lastYear:
            return 70 // Standard height
        case .all:
            return 80 // Taller for comprehensive view
        }
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
                            Text(chartSubtitle)
                                .font(.caption)
                                .foregroundColor(FintechColors.textSecondary)
                            Spacer()
                            Text("\(filteredData.count) months")
                                .font(.caption)
                                .foregroundColor(FintechColors.textSecondary)
                        }
                        
                        TrendLineView(data: filteredData, timeRange: selectedTimeRange)
                            .frame(height: chartHeight)
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
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: abs(value))) ?? "0"
    }
}

enum FinancialTimeRange: CaseIterable {
    case last3Months, last6Months, lastYear, all
    
    var displayName: String {
        switch self {
        case .last3Months: return "3M"
        case .last6Months: return "6M"
        case .lastYear: return "1Y"
        case .all: return "All"
        }
    }
    
    var fullDisplayName: String {
        switch self {
        case .last3Months: return "Last 3 Months"
        case .last6Months: return "Last 6 Months"
        case .lastYear: return "Last Year"
        case .all: return "All Time"
        }
    }
}

enum ChartTrendDirection {
    case up, down, neutral
}

struct TrendIndicator: View {
    let direction: ChartTrendDirection
    
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
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: abs(value))) ?? "0"
    }
}

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
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
} 