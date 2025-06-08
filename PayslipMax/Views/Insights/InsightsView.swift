import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \PayslipItem.timestamp, order: .reverse) private var payslips: [PayslipItem]
    @StateObject private var viewModel: InsightsViewModel
    @State private var selectedTimeRange: FinancialTimeRange = .last6Months
    
    init(viewModel: InsightsViewModel? = nil) {
        // Use provided viewModel or create one from DIContainer
        let model = viewModel ?? DIContainer.shared.makeInsightsViewModel()
        self._viewModel = StateObject(wrappedValue: model)
    }
    
    // Computed property to filter payslips based on selected time range
    private var filteredPayslips: [PayslipItem] {
        let sortedPayslips = payslips.sorted(by: { $0.timestamp > $1.timestamp })
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .last6Months:
            guard let cutoffDate = calendar.date(byAdding: .month, value: -6, to: now) else {
                return sortedPayslips
            }
            return sortedPayslips.filter { $0.timestamp >= cutoffDate }
            
        case .lastYear:
            guard let cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) else {
                return sortedPayslips
            }
            return sortedPayslips.filter { $0.timestamp >= cutoffDate }
            
        case .last2Years:
            guard let cutoffDate = calendar.date(byAdding: .year, value: -2, to: now) else {
                return sortedPayslips
            }
            return sortedPayslips.filter { $0.timestamp >= cutoffDate }
            
        case .all:
            return sortedPayslips
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header section with filtered data
                        headerSection
                        
                        // Chart section with coordinated time range
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
                viewModel.refreshData(payslips: filteredPayslips)
            }
            .onChange(of: selectedTimeRange) {
                // Update view model when time range changes
                viewModel.refreshData(payslips: filteredPayslips)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and metadata
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
                    
                    Text(viewModel.lastUpdated)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                }
            }
            
            // Financial metrics - optimized horizontal layout
            VStack(spacing: 12) {
                // Total Income
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundColor(FintechColors.successGreen)
                            .font(.title3)
                        
                        Text("Total Income")
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text("₹\(String(format: "%.0f", viewModel.totalIncome))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                        
                        if viewModel.incomeTrend != 0 {
                            TrendBadge(changePercent: viewModel.incomeTrend)
                        }
                    }
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
                    
                    HStack(spacing: 8) {
                        Text("₹\(String(format: "%.0f", viewModel.totalDeductions))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                        
                        if viewModel.deductionsTrend != 0 {
                            TrendBadge(changePercent: viewModel.deductionsTrend)
                        }
                    }
                }
                
                // Net Income
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "banknote.fill")
                            .foregroundColor(FintechColors.primaryBlue)
                            .font(.title3)
                        
                        Text("Net Income")
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text("₹\(String(format: "%.0f", viewModel.netIncome))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                        
                        if viewModel.netIncomeTrend != 0 {
                            TrendBadge(changePercent: viewModel.netIncomeTrend)
                        }
                    }
                }
                
                // Average Monthly
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundColor(FintechColors.chartSecondary)
                            .font(.title3)
                        
                        Text("Average Monthly")
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("₹\(String(format: "%.0f", viewModel.averageMonthlyIncome))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                    // No trend for average monthly
                }
            }
        }
        .fintechCardStyle()
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        // Use coordinated time range with external filtering
        FinancialOverviewCard(
            payslips: filteredPayslips,
            selectedTimeRange: $selectedTimeRange,
            useExternalFiltering: true
        )
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

