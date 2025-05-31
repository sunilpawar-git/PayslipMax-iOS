import SwiftUI
import Charts

struct FinancialOverviewCard: View {
    let payslips: [PayslipItem]
    @State private var selectedTimeRange: FinancialTimeRange = .last6Months
    
    private var filteredData: [PayslipItem] {
        let sortedPayslips = payslips.sorted(by: { $0.timestamp > $1.timestamp })
        let now = Date()
        let calendar = Calendar.current
        
        print("🔍 FinancialOverviewCard Debug:")
        print("Total payslips: \(payslips.count)")
        print("Selected time range: \(selectedTimeRange)")
        print("Current date: \(now)")
        
        // Print all payslip timestamps for debugging
        for (index, payslip) in sortedPayslips.enumerated() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            print("Payslip \(index): \(payslip.month) \(payslip.year) - \(formatter.string(from: payslip.timestamp))")
        }
        
        switch selectedTimeRange {
        case .last6Months:
            // Use a more inclusive 6-month calculation
            guard let cutoffDate = calendar.date(byAdding: .month, value: -6, to: now) else {
                print("❌ Failed to calculate 6 month cutoff date")
                return sortedPayslips
            }
            
            // For 6M, also include current month data more inclusively
            let startOfCutoffMonth = calendar.dateInterval(of: .month, for: cutoffDate)?.start ?? cutoffDate
            
            print("6M cutoff date: \(cutoffDate)")
            print("6M start of cutoff month: \(startOfCutoffMonth)")
            
            let filtered = sortedPayslips.filter { payslip in
                let isIncluded = payslip.timestamp >= startOfCutoffMonth
                print("  Payslip \(payslip.month) \(payslip.year): \(isIncluded ? "✅ INCLUDED" : "❌ excluded")")
                return isIncluded
            }
            
            print("6M filtered result: \(filtered.count) payslips")
            return filtered
            
        case .lastYear:
            guard let cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) else {
                print("❌ Failed to calculate 1 year cutoff date")
                return sortedPayslips
            }
            print("1Y cutoff date: \(cutoffDate)")
            let filtered = sortedPayslips.filter { $0.timestamp >= cutoffDate }
            print("1Y filtered result: \(filtered.count) payslips")
            return filtered
            
        case .last2Years:
            guard let cutoffDate = calendar.date(byAdding: .year, value: -2, to: now) else {
                print("❌ Failed to calculate 2 year cutoff date")
                return sortedPayslips
            }
            print("2Y cutoff date: \(cutoffDate)")
            let filtered = sortedPayslips.filter { $0.timestamp >= cutoffDate }
            print("2Y filtered result: \(filtered.count) payslips")
            return filtered
            
        case .all:
            print("ALL: returning all \(sortedPayslips.count) payslips")
            return sortedPayslips
        }
    }
    
    private var totalNet: Double {
        let net = filteredData.reduce(0) { $0 + ($1.credits - $1.debits) }
        print("💰 Total net for \(selectedTimeRange): ₹\(net)")
        return net
    }
    
    private var averageMonthly: Double {
        guard !filteredData.isEmpty else { return 0 }
        return totalNet / Double(filteredData.count)
    }
    
    private var trendDirection: TrendDirection {
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
        case .last6Months:
            return "6-month trend"
        case .lastYear:
            return "Annual trend"
        case .last2Years:
            return "2-year overview"
        case .all:
            return "Complete history"
        }
    }
    
    private var chartHeight: CGFloat {
        switch selectedTimeRange {
        case .last6Months:
            return 60 // Compact for fewer data points
        case .lastYear:
            return 70 // Standard height
        case .last2Years:
            return 80 // Slightly taller for more data
        case .all:
            return 80 // Taller for comprehensive view
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with time range selector
            HStack {
                Text("Financial Overview")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(FinancialTimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            // Main summary section
            VStack(spacing: 12) {
                // Net worth display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Net Flow")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Text("₹\(formatCurrency(totalNet))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(totalNet >= 0 ? .green : .red)
                            
                            TrendIndicator(direction: trendDirection)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Monthly Avg")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("₹\(formatCurrency(averageMonthly))")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                // Simplified trend line
                if !filteredData.isEmpty {
                    VStack(spacing: 8) {
                        // Add a subtitle for the chart based on time range
                        HStack {
                            Text(chartSubtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(filteredData.count) months")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No payslips in this period")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 60)
                    }
                }
                
                // Quick stats row
                HStack(spacing: 16) {
                    QuickStatCard(
                        title: "Total Credits",
                        value: filteredData.reduce(0) { $0 + $1.credits },
                        color: .green
                    )
                    
                    QuickStatCard(
                        title: "Total Debits", 
                        value: filteredData.reduce(0) { $0 + $1.debits },
                        color: .red
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2) // Add subtle shadow
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
    case last6Months, lastYear, last2Years, all
    
    var displayName: String {
        switch self {
        case .last6Months: return "6M"
        case .lastYear: return "1Y"
        case .last2Years: return "2Y" 
        case .all: return "All"
        }
    }
    
    var fullDisplayName: String {
        switch self {
        case .last6Months: return "Last 6 Months"
        case .lastYear: return "Last Year"
        case .last2Years: return "Last 2 Years" 
        case .all: return "All Time"
        }
    }
}

enum TrendDirection {
    case up, down, neutral
}

struct TrendIndicator: View {
    let direction: TrendDirection
    
    var body: some View {
        Group {
            switch direction {
            case .up:
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.green)
            case .down:
                Image(systemName: "arrow.down.right")
                    .foregroundColor(.red)
            case .neutral:
                Image(systemName: "minus")
                    .foregroundColor(.orange)
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
    
    private var lineStyle: StrokeStyle {
        switch timeRange {
        case .last6Months:
            return StrokeStyle(lineWidth: 3, lineCap: .round) // Thicker for less data
        case .lastYear:
            return StrokeStyle(lineWidth: 2.5, lineCap: .round)
        case .last2Years, .all:
            return StrokeStyle(lineWidth: 2, lineCap: .round) // Thinner for more data
        }
    }
    
    private var symbolSize: CGFloat {
        switch timeRange {
        case .last6Months:
            return 40 // Larger symbols for fewer points
        case .lastYear:
            return 30
        case .last2Years, .all:
            return 25 // Smaller symbols for more dense data
        }
    }
    
    private var showDataPoints: Bool {
        switch timeRange {
        case .last6Months:
            return true // Always show points for 6M
        case .lastYear:
            return data.count <= 12 // Show points if 12 or fewer
        case .last2Years, .all:
            return data.count <= 8 // Only show points if very sparse data
        }
    }
    
    var body: some View {
        Group {
            if data.isEmpty {
                // Show empty state
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.secondary)
                    Text("No data available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if data.count == 1 {
                // Show single point as a dot with label
                VStack(spacing: 4) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                    Text("₹\(formatCurrency(data.first!.credits - data.first!.debits))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Show full chart with time-range specific styling
                Chart {
                    ForEach(chartData, id: \.index) { dataPoint in
                        LineMark(
                            x: .value("Period", dataPoint.index),
                            y: .value("Net", dataPoint.value)
                        )
                        .foregroundStyle(.blue.gradient)
                        .lineStyle(lineStyle)
                        
                        AreaMark(
                            x: .value("Period", dataPoint.index),
                            y: .value("Net", dataPoint.value)
                        )
                        .foregroundStyle(.blue.opacity(timeRange == .last6Months ? 0.2 : 0.1))
                        
                        // Conditionally add point markers
                        if showDataPoints {
                            PointMark(
                                x: .value("Period", dataPoint.index),
                                y: .value("Net", dataPoint.value)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(symbolSize)
                        }
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: .automatic(includesZero: false))
                .animation(.easeInOut(duration: 0.5), value: timeRange) // Smooth transitions
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
                .foregroundColor(.secondary)
            
            Text("₹\(formatCurrency(value))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.2), lineWidth: 1)
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