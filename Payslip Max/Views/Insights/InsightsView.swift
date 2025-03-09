import SwiftUI
import Charts
import SwiftData

struct InsightsView: View {
    @StateObject private var viewModel = DIContainer.shared.makeInsightsViewModel()
    @Query(sort: \PayslipItem.timestamp, order: .reverse) private var payslips: [PayslipItem]
    
    @State private var selectedTimeRange: TimeRange = .year
    @State private var selectedInsightType: InsightType = .income
    @State private var selectedChartType: ChartType = .bar
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range selector
                    timeRangeSelector
                    
                    // Summary cards
                    summaryCards
                    
                    // Chart section
                    chartSection
                    
                    // Insights section
                    insightsSection
                    
                    // Trends section
                    trendsSection
                }
                .padding()
            }
            .navigationTitle("Financial Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshData(payslips: payslips.map { $0 as any PayslipItemProtocol })
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .errorAlert(error: $viewModel.error)
        }
        .onAppear {
            viewModel.refreshData(payslips: payslips.map { $0 as any PayslipItemProtocol })
        }
    }
    
    // MARK: - View Components
    
    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedTimeRange) { _, newValue in
            viewModel.updateTimeRange(newValue)
        }
    }
    
    private var summaryCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                SummaryCard(
                    title: "Total Income",
                    value: "₹\(viewModel.totalIncome, specifier: "%.2f")",
                    trend: viewModel.incomeTrend,
                    icon: "arrow.up.right",
                    color: .green
                )
                
                SummaryCard(
                    title: "Total Deductions",
                    value: "₹\(viewModel.totalDeductions, specifier: "%.2f")",
                    trend: viewModel.deductionsTrend,
                    icon: "arrow.down.right",
                    color: .red
                )
                
                SummaryCard(
                    title: "Net Income",
                    value: "₹\(viewModel.netIncome, specifier: "%.2f")",
                    trend: viewModel.netIncomeTrend,
                    icon: "creditcard",
                    color: .blue
                )
                
                SummaryCard(
                    title: "Tax Paid",
                    value: "₹\(viewModel.totalTax, specifier: "%.2f")",
                    trend: viewModel.taxTrend,
                    icon: "building.columns",
                    color: .purple
                )
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Financial Overview")
                    .font(.headline)
                
                Spacer()
                
                Picker("Chart Type", selection: $selectedChartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.iconName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Data Type", selection: $selectedInsightType) {
                    ForEach(InsightType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            
            if viewModel.chartData.isEmpty {
                emptyChartView
            } else {
                chartView
                    .frame(height: 250)
            }
            
            // Legend
            HStack(spacing: 16) {
                ForEach(viewModel.legendItems, id: \.label) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 10, height: 10)
                        
                        Text(item.label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var chartView: some View {
        if #available(iOS 16.0, *) {
            modernChartView
        } else {
            legacyChartView
        }
    }
    
    @available(iOS 16.0, *)
    private var modernChartView: some View {
        Chart {
            ForEach(viewModel.chartData) { item in
                switch selectedChartType {
                case .bar:
                    BarMark(
                        x: .value("Period", item.label),
                        y: .value("Amount", item.value)
                    )
                    .foregroundStyle(by: .value("Category", item.category))
                
                case .line:
                    LineMark(
                        x: .value("Period", item.label),
                        y: .value("Amount", item.value)
                    )
                    .foregroundStyle(by: .value("Category", item.category))
                    .symbol(by: .value("Category", item.category))
                
                case .area:
                    AreaMark(
                        x: .value("Period", item.label),
                        y: .value("Amount", item.value)
                    )
                    .foregroundStyle(by: .value("Category", item.category))
                    .opacity(0.7)
                
                case .pie:
                    if selectedInsightType == .breakdown {
                        SectorMark(
                            angle: .value("Amount", item.value),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Category", item.category))
                    } else {
                        BarMark(
                            x: .value("Period", item.label),
                            y: .value("Amount", item.value)
                        )
                        .foregroundStyle(by: .value("Category", item.category))
                    }
                }
            }
        }
    }
    
    private var legacyChartView: some View {
        GeometryReader { geometry in
            if selectedChartType == .pie && selectedInsightType == .breakdown {
                // Simple pie chart for iOS 15
                ZStack {
                    ForEach(Array(viewModel.pieChartSegments.enumerated()), id: \.element.label) { index, segment in
                        PieSegment(
                            startAngle: segment.startAngle,
                            endAngle: segment.endAngle,
                            color: viewModel.colorForCategory(segment.label)
                        )
                    }
                    
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: min(geometry.size.width, geometry.size.height) * 0.5)
                    
                    Text("Total\n₹\(viewModel.totalForSelectedInsight, specifier: "%.0f")")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            } else {
                // Bar chart for other types
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(viewModel.chartData) { item in
                        VStack {
                            Rectangle()
                                .fill(viewModel.colorForCategory(item.category))
                                .frame(
                                    width: (geometry.size.width - CGFloat(viewModel.chartData.count) * 8) / CGFloat(viewModel.chartData.count),
                                    height: CGFloat(item.value / viewModel.maxChartValue) * geometry.size.height * 0.8
                                )
                            
                            Text(item.label)
                                .font(.caption)
                                .frame(height: 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
    
    private var emptyChartView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No data available")
                .font(.headline)
            
            Text("Upload more payslips to see insights")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.headline)
            
            if viewModel.insights.isEmpty {
                Text("Not enough data to generate insights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.insights, id: \.title) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends & Predictions")
                .font(.headline)
            
            if viewModel.trends.isEmpty {
                Text("Not enough data to analyze trends")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.trends, id: \.title) { trend in
                    TrendCard(trend: trend)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let trend: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
                
                Spacer()
                
                if trend != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: trend > 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        
                        Text("\(abs(trend), specifier: "%.1f")%")
                            .font(.caption2)
                    }
                    .foregroundColor(trend > 0 ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(trend > 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    )
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding()
        .frame(width: 160, height: 120)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct InsightCard: View {
    let insight: InsightItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: insight.iconName)
                .font(.title2)
                .foregroundColor(insight.color)
                .frame(width: 40, height: 40)
                .background(insight.color.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)
                
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct TrendCard: View {
    let trend: TrendItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: trend.iconName)
                .font(.title2)
                .foregroundColor(trend.color)
                .frame(width: 40, height: 40)
                .background(trend.color.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trend.title)
                    .font(.headline)
                
                Text(trend.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let value = trend.value {
                    Text(value)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(trend.color.opacity(0.2))
                        .cornerRadius(4)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct PieSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
    case all = "All Time"
    
    var displayName: String {
        return self.rawValue
    }
}

enum InsightType: String, CaseIterable {
    case income = "Income"
    case deductions = "Deductions"
    case net = "Net Income"
    case breakdown = "Breakdown"
    
    var displayName: String {
        return self.rawValue
    }
}

enum ChartType: String, CaseIterable {
    case bar = "Bar"
    case line = "Line"
    case area = "Area"
    case pie = "Pie"
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .bar: return "chart.bar"
        case .line: return "chart.line.uptrend.xyaxis"
        case .area: return "chart.area.fill"
        case .pie: return "chart.pie"
        }
    }
}

struct InsightItem {
    let title: String
    let description: String
    let iconName: String
    let color: Color
}

struct TrendItem {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let value: String?
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let category: String
}

struct LegendItem {
    let label: String
    let color: Color
}

struct PieSegmentData {
    let label: String
    let value: Double
    let startAngle: Angle
    let endAngle: Angle
}

// MARK: - Preview

struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView()
    }
} 