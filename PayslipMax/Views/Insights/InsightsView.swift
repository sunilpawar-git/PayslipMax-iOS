import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \PayslipItem.timestamp, order: .reverse) private var payslips: [PayslipItem]
    @StateObject private var viewModel: InsightsViewModel
    @State private var selectedTimeRange: FinancialTimeRange = .last3Months
    
    init(viewModel: InsightsViewModel? = nil) {
        // Use provided viewModel or create one from DIContainer
        let model = viewModel ?? DIContainer.shared.makeInsightsViewModel()
        self._viewModel = StateObject(wrappedValue: model)
    }
    
    // Computed property to filter payslips based on selected time range
    private var filteredPayslips: [PayslipItem] {
        let sortedPayslips = payslips.sorted(by: { 
            let date1 = createDateFromPayslip($0)
            let date2 = createDateFromPayslip($1)
            return date1 > date2
        })
        let now = Date()
        let calendar = Calendar.current
        
        print("🔍 InsightsView filtering: Total payslips: \(payslips.count), Selected range: \(selectedTimeRange)")
        
        // Debug: Print payslip date ranges using period dates (not timestamps)
        if !sortedPayslips.isEmpty {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let oldestDate = createDateFromPayslip(sortedPayslips.last!)
            let newestDate = createDateFromPayslip(sortedPayslips.first!)
            print("📅 Payslip period range: \(formatter.string(from: oldestDate)) to \(formatter.string(from: newestDate))")
        }
        
        switch selectedTimeRange {
        case .last3Months:
            guard let cutoffDate = calendar.date(byAdding: .month, value: -3, to: now) else {
                print("❌ Failed to calculate 3M cutoff date")
                return sortedPayslips
            }
            let filtered = sortedPayslips.filter { createDateFromPayslip($0) >= cutoffDate }
            print("✅ 3M filter: \(filtered.count) out of \(sortedPayslips.count) payslips")
            return filtered
            
        case .last6Months:
            guard let cutoffDate = calendar.date(byAdding: .month, value: -6, to: now) else {
                print("❌ Failed to calculate 6M cutoff date")
                return sortedPayslips
            }
            let filtered = sortedPayslips.filter { createDateFromPayslip($0) >= cutoffDate }
            print("✅ 6M filter: \(filtered.count) out of \(sortedPayslips.count) payslips")
            return filtered
            
        case .lastYear:
            guard let cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) else {
                print("❌ Failed to calculate 1Y cutoff date")
                return sortedPayslips
            }
            let filtered = sortedPayslips.filter { createDateFromPayslip($0) >= cutoffDate }
            print("✅ 1Y filter: \(filtered.count) out of \(sortedPayslips.count) payslips")
            return filtered
            
        case .all:
            print("✅ ALL filter: returning all \(sortedPayslips.count) payslips")
            return sortedPayslips
        }
    }
    
    /// Creates a Date object from a payslip's period (month/year), not the creation timestamp
    /// This matches the logic used in PayslipsView for consistent date handling
    private func createDateFromPayslip(_ payslip: PayslipItem) -> Date {
        // Always use the payslip period (month/year) for insights filtering
        // not the creation timestamp which is always recent
        let monthInt = monthToInt(payslip.month)
        let year = payslip.year
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = monthInt > 0 ? monthInt : 1 // Default to January if month parsing fails
        dateComponents.day = 1 // Use first day of the month
        
        return Calendar.current.date(from: dateComponents) ?? Date.distantPast
    }
    
    /// Determines if trend badges should be shown based on data quality
    private var shouldShowTrendBadge: Bool {
        // Only show trends for meaningful time ranges with sufficient data
        return filteredPayslips.count >= 6 && selectedTimeRange != .all
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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Time range picker - Controls entire screen data
                        timeRangePickerSection
                        
                        // Financial metrics based on selected time range
                        financialMetricsSection
                        
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
    
    // MARK: - Financial Metrics Section
    
    private var financialMetricsSection: some View {
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
                    
                    if shouldShowTrendBadge {
                        Text("Percentages show change between periods")
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                            .opacity(0.8)
                    }
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
                        Text("₹\(Formatters.formatIndianCurrency(viewModel.totalIncome))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                        
                        if shouldShowTrendBadge && viewModel.incomeTrend != 0 {
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
                        Text("₹\(Formatters.formatIndianCurrency(viewModel.totalDeductions))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                        
                        if shouldShowTrendBadge && viewModel.deductionsTrend != 0 {
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
                        Text("₹\(Formatters.formatIndianCurrency(viewModel.netIncome))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                        
                        if shouldShowTrendBadge && viewModel.netIncomeTrend != 0 {
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
                    
                    Text("₹\(Formatters.formatIndianCurrency(viewModel.averageMonthlyIncome))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                    // No trend for average monthly
                }
            }
        }
        .fintechCardStyle()
    }
    
    // MARK: - Time Range Picker Section
    
    private var timeRangePickerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Insights Period")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    Text("Controls all data displayed below")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
                
                Spacer()
                
                // Selected range indicator
                HStack(spacing: 4) {
                    Image(systemName: "calendar.circle.fill")
                        .foregroundColor(FintechColors.primaryBlue)
                        .font(.caption)
                    
                    Text(selectedTimeRange.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.primaryBlue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    FintechColors.primaryBlue.opacity(0.1)
                        .cornerRadius(6)
                )
            }
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(FinancialTimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .animation(.easeInOut(duration: 0.3), value: selectedTimeRange)
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
                    
                    Text("±₹\(Formatters.formatIndianCurrency(viewModel.incomeVariation))")
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
            
            Text("₹\(Formatters.formatIndianCurrency(amount))")
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

