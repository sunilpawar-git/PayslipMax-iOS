import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \PayslipItem.timestamp, order: .reverse) private var payslips: [PayslipItem]
    @StateObject private var viewModel: InsightsViewModel
    
    @State private var selectedTimeRange: TimeRange = .year
    @State private var selectedInsightType: InsightType = .income
    @State private var selectedChartType: ChartType = .bar
    
    init(viewModel: InsightsViewModel? = nil) {
        // Use provided viewModel or create one from DIContainer
        let model = viewModel ?? DIContainer.shared.makeInsightsViewModel()
        self._viewModel = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header section
                        headerSection
                        
                        // Time range selector
                        timeRangeSelector
                        
                        // Summary cards
                        summaryCardsSection
                        
                        // Chart section
                        chartSection
                        
                        // Key insights
                        keyInsightsSection
                        
                        // Detailed analysis
                        detailedAnalysisSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.refreshData(payslips: payslips)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Financial Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    Text("Analyzed \(payslips.count) payslip\(payslips.count != 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                }
                
                Spacer()
                
                // Quick stats
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last Updated")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    
                    Text(viewModel.lastUpdated)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                }
            }
        }
        .fintechCardStyle()
    }
    
    // MARK: - Time Range Selector
    
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
    
    // MARK: - Summary Cards Section
    
    private var summaryCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                SummaryCard(
                    title: "Total Income",
                    value: "₹\(String(format: "%.0f", viewModel.totalIncome))",
                    trend: viewModel.incomeTrend,
                    icon: "arrow.up.right.circle.fill",
                    color: FintechColors.successGreen
                )
                
                SummaryCard(
                    title: "Total Deductions",
                    value: "₹\(String(format: "%.0f", viewModel.totalDeductions))",
                    trend: viewModel.deductionsTrend,
                    icon: "arrow.down.right.circle.fill",
                    color: FintechColors.dangerRed
                )
                
                SummaryCard(
                    title: "Net Income",
                    value: "₹\(String(format: "%.0f", viewModel.netIncome))",
                    trend: viewModel.netIncomeTrend,
                    icon: "banknote.fill",
                    color: FintechColors.primaryBlue
                )
                
                SummaryCard(
                    title: "Average Monthly",
                    value: "₹\(String(format: "%.0f", viewModel.averageMonthlyIncome))",
                    trend: 0.0, // No trend for average
                    icon: "calendar.circle.fill",
                    color: FintechColors.chartSecondary
                )
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Trends")
                    .font(.headline)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                HStack(spacing: 8) {
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
            }
            
            InsightsChartView(
                chartData: viewModel.chartData,
                legendItems: viewModel.legendItems,
                selectedChartType: selectedChartType
            )
        }
        .fintechCardStyle()
    }
    
    // MARK: - Key Insights Section
    
    private var keyInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(viewModel.insights, id: \.title) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
        .fintechCardStyle()
    }
    
    // MARK: - Detailed Analysis Section
    
    private var detailedAnalysisSection: some View {
        VStack(spacing: 16) {
            // Income stability
            if viewModel.hasMultiplePayslips {
                incomeStabilityCard
            }
            
            // Top earnings/deductions
            topCategoriesCard
            
            // Monthly patterns
            if viewModel.hasYearlyData {
                monthlyPatternsCard
            }
        }
    }
    
    private var incomeStabilityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(FintechColors.primaryBlue)
                
                Text("Income Stability")
                    .font(.headline)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                Text(viewModel.incomeStabilityDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.incomeStabilityColor)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Variation:")
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                    
                    Spacer()
                    
                    Text("±₹\(String(format: "%.0f", viewModel.incomeVariation))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                }
                
                Text(viewModel.stabilityAnalysis)
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .fintechCardStyle()
    }
    
    private var topCategoriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Categories")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            VStack(spacing: 8) {
                ForEach(viewModel.topEarnings.prefix(3), id: \.category) { item in
                    CategoryRow(
                        category: item.category,
                        amount: item.amount,
                        percentage: item.percentage,
                        color: FintechColors.successGreen,
                        isIncome: true
                    )
                }
                
                Divider()
                    .background(FintechColors.divider)
                
                ForEach(viewModel.topDeductions.prefix(3), id: \.category) { item in
                    CategoryRow(
                        category: item.category,
                        amount: item.amount,
                        percentage: item.percentage,
                        color: FintechColors.dangerRed,
                        isIncome: false
                    )
                }
            }
        }
        .fintechCardStyle()
    }
    
    private var monthlyPatternsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(FintechColors.primaryBlue)
                
                Text("Monthly Patterns")
                    .font(.headline)
                    .foregroundColor(FintechColors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                PatternRow(
                    title: "Best Month",
                    value: viewModel.bestMonth,
                    color: FintechColors.successGreen
                )
                
                PatternRow(
                    title: "Lowest Month",
                    value: viewModel.worstMonth,
                    color: FintechColors.dangerRed
                )
                
                PatternRow(
                    title: "Most Consistent",
                    value: viewModel.mostConsistentMonth,
                    color: FintechColors.primaryBlue
                )
            }
        }
        .fintechCardStyle()
    }
}

// MARK: - Supporting Views

struct InsightCard: View {
    let insight: InsightItem
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(insight.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: insight.iconName)
                    .foregroundColor(insight.color)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct CategoryRow: View {
    let category: String
    let amount: Double
    let percentage: Double
    let color: Color
    let isIncome: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)
                
                Text("\(percentage, specifier: "%.1f")% of \(isIncome ? "income" : "deductions")")
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
            }
            
            Spacer()
            
            Text("₹\(String(format: "%.0f", amount))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct PatternRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct TrendBadge: View {
    let trend: Double
    
    private var trendColor: Color {
        FintechColors.getTrendColor(for: trend)
    }
    
    private var trendIcon: String {
        if trend > 0.05 {
            return "arrow.up"
        } else if trend < -0.05 {
            return "arrow.down"
        } else {
            return "minus"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trendIcon)
                .font(.caption2)
            Text("\(abs(trend * 100), specifier: "%.1f")%")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(trendColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(trendColor.opacity(0.1))
        )
    }
} 