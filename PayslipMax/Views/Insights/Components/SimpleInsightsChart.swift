import SwiftUI
import Charts

struct SimpleInsightsChart: View {
    let payslips: [PayslipItem]
    @State private var selectedTimeRange: InsightsTimeRange = .sixMonths
    @State private var selectedDataType: InsightsDataType = .netPay
    
    // Computed property for filtered payslips based on time range
    private var filteredPayslips: [PayslipItem] {
        let sortedPayslips = payslips.sorted(by: { $0.timestamp > $1.timestamp })
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .sixMonths:
            guard let cutoffDate = calendar.date(byAdding: .month, value: -6, to: now) else {
                return sortedPayslips
            }
            return sortedPayslips.filter { $0.timestamp >= cutoffDate }
            
        case .oneYear:
            guard let cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) else {
                return sortedPayslips
            }
            return sortedPayslips.filter { $0.timestamp >= cutoffDate }
            
        case .twoYears:
            guard let cutoffDate = calendar.date(byAdding: .year, value: -2, to: now) else {
                return sortedPayslips
            }
            return sortedPayslips.filter { $0.timestamp >= cutoffDate }
            
        case .all:
            return sortedPayslips
        }
    }
    
    // Computed property for chart data
    private var chartData: [InsightsChartDataPoint] {
        return filteredPayslips.map { payslip in
            let value: Double
            switch selectedDataType {
            case .earnings:
                value = payslip.credits
            case .deductions:
                value = payslip.debits
            case .otherAllowances:
                // Calculate other allowances (earnings that are not basic pay)
                let basicPay = payslip.earnings["BPAY"] ?? 0
                value = max(0, payslip.credits - basicPay)
            case .netPay:
                value = payslip.credits - payslip.debits
            }
            
            return InsightsChartDataPoint(
                month: payslip.month,
                year: payslip.year,
                timestamp: payslip.timestamp,
                value: value
            )
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    private var currentValue: Double {
        chartData.last?.value ?? 0
    }
    
    private var previousValue: Double {
        guard chartData.count >= 2 else { return currentValue }
        return chartData[chartData.count - 2].value
    }
    
    private var changePercent: Double {
        guard previousValue != 0 else { return 0 }
        return ((currentValue - previousValue) / previousValue) * 100
    }
    
    private var averageValue: Double {
        guard !chartData.isEmpty else { return 0 }
        return chartData.reduce(0) { $0 + $1.value } / Double(chartData.count)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with current value and trend
            headerSection
            
            // Time range selector
            timeRangeSelector
            
            // Data type selector
            dataTypeSelector
            
            // Chart section with explicit refresh key
            chartSection
                .id("chart-\(selectedTimeRange.displayName)-\(selectedDataType.displayName)-\(chartData.count)")
            
            // Summary stats
            summarySection
        }
        .fintechCardStyle()
        .animation(.easeInOut(duration: 0.3), value: selectedTimeRange)
        .animation(.easeInOut(duration: 0.3), value: selectedDataType)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(selectedDataType.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                if !chartData.isEmpty {
                    TrendBadge(changePercent: changePercent)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    
                    Text("₹\(formatCurrency(currentValue))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(selectedDataType.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Average")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    
                    Text("₹\(formatCurrency(averageValue))")
                        .font(.headline)
                        .foregroundColor(FintechColors.textPrimary)
                }
            }
        }
    }
    
    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(InsightsTimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var dataTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InsightsDataType.allCases, id: \.self) { dataType in
                    DataTypeButton(
                        dataType: dataType,
                        isSelected: selectedDataType == dataType
                    ) {
                        selectedDataType = dataType
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var chartSection: some View {
        Group {
            if !chartData.isEmpty {
                Chart(chartData) { dataPoint in
                    AreaMark(
                        x: .value("Month", dataPoint.timestamp),
                        y: .value(selectedDataType.displayName, dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                selectedDataType.color.opacity(0.3),
                                selectedDataType.color.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Month", dataPoint.timestamp),
                        y: .value(selectedDataType.displayName, dataPoint.value)
                    )
                    .foregroundStyle(selectedDataType.color)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    PointMark(
                        x: .value("Month", dataPoint.timestamp),
                        y: .value(selectedDataType.displayName, dataPoint.value)
                    )
                    .foregroundStyle(selectedDataType.color)
                    .symbolSize(50)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(FintechColors.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(FintechColors.textSecondary)
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(Color.clear)
                }
                .id("inner-chart-\(selectedTimeRange.displayName)-\(selectedDataType.displayName)")
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(FintechColors.textSecondary.opacity(0.5))
                    
                    Text("No data for \(selectedTimeRange.displayName)")
                        .font(.headline)
                        .foregroundColor(FintechColors.textSecondary)
                    
                    Text("Upload payslips to see \(selectedDataType.displayName.lowercased()) trends")
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
            }
        }
    }
    
    private var summarySection: some View {
        HStack(spacing: 16) {
            SummaryStatCard(
                title: "Highest",
                value: chartData.max(by: { $0.value < $1.value })?.value ?? 0,
                color: FintechColors.successGreen
            )
            
            SummaryStatCard(
                title: "Lowest", 
                value: chartData.min(by: { $0.value < $1.value })?.value ?? 0,
                color: FintechColors.dangerRed
            )
            
            SummaryStatCard(
                title: "Total",
                value: chartData.reduce(0) { $0 + $1.value },
                color: FintechColors.primaryBlue
            )
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

// MARK: - Supporting Types

enum InsightsTimeRange: CaseIterable {
    case sixMonths, oneYear, twoYears, all
    
    var displayName: String {
        switch self {
        case .sixMonths: return "6M"
        case .oneYear: return "1Y"
        case .twoYears: return "2Y"
        case .all: return "All"
        }
    }
}

enum InsightsDataType: CaseIterable {
    case earnings, deductions, otherAllowances, netPay
    
    var displayName: String {
        switch self {
        case .earnings: return "Earnings"
        case .deductions: return "Deductions"
        case .otherAllowances: return "Other Allowances"
        case .netPay: return "Net Pay"
        }
    }
    
    var color: Color {
        switch self {
        case .earnings: return FintechColors.successGreen
        case .deductions: return FintechColors.dangerRed
        case .otherAllowances: return FintechColors.chartSecondary
        case .netPay: return FintechColors.primaryBlue
        }
    }
    
    var icon: String {
        switch self {
        case .earnings: return "arrow.up.circle.fill"
        case .deductions: return "arrow.down.circle.fill"
        case .otherAllowances: return "plus.circle.fill"
        case .netPay: return "banknote.fill"
        }
    }
}

struct InsightsChartDataPoint: Identifiable {
    let id = UUID()
    let month: String
    let year: Int
    let timestamp: Date
    let value: Double
}

// MARK: - Supporting Views

struct TrendBadge: View {
    let changePercent: Double
    
    private var isPositive: Bool { changePercent >= 0 }
    private var color: Color { 
        isPositive ? FintechColors.successGreen : FintechColors.dangerRed 
    }
    private var icon: String { 
        isPositive ? "arrow.up" : "arrow.down" 
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            
            Text("\(abs(changePercent), specifier: "%.1f")%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DataTypeButton: View {
    let dataType: InsightsDataType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: dataType.icon)
                    .font(.caption)
                
                Text(dataType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : dataType.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? dataType.color : dataType.color.opacity(0.1)
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SummaryStatCard: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)
            
            Text("₹\(formatCurrency(value))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: abs(value))) ?? "0"
    }
}

#Preview {
    SimpleInsightsChart(payslips: [
        PayslipItem(
            timestamp: Date(),
            month: "December",
            year: 2024,
            credits: 85000,
            debits: 25000,
            dsop: 8000,
            tax: 15000,
            earnings: ["BPAY": 60000, "DA": 20000, "HRA": 5000],
            deductions: ["ITAX": 15000, "DSOP": 8000, "CGEGIS": 2000]
        )
    ])
    .padding()
} 