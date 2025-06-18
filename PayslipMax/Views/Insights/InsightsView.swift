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
        
        // Use the latest payslip's period as the reference point instead of current date
        // This ensures we get the correct count (12 for 1Y, 6 for 6M, 3 for 3M)
        guard let latestPayslip = sortedPayslips.first else {
            print("❌ No payslips available")
            return []
        }
        
        let latestPayslipDate = createDateFromPayslip(latestPayslip)
        let calendar = Calendar.current
        
        print("🔍 InsightsView filtering: Total payslips: \(payslips.count), Selected range: \(selectedTimeRange)")
        print("📅 Latest payslip period: \(latestPayslip.month) \(latestPayslip.year)")
        
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
            // Calculate 3 months back from the latest payslip month
            guard let cutoffDate = calendar.date(byAdding: .month, value: -2, to: latestPayslipDate) else {
                print("❌ Failed to calculate 3M cutoff date")
                return sortedPayslips
            }
            let filtered = sortedPayslips.filter { createDateFromPayslip($0) >= cutoffDate }
            print("✅ 3M filter: \(filtered.count) out of \(sortedPayslips.count) payslips (from \(DateFormatter().string(from: cutoffDate)))")
            return filtered
            
        case .last6Months:
            // Calculate 6 months back from the latest payslip month
            guard let cutoffDate = calendar.date(byAdding: .month, value: -5, to: latestPayslipDate) else {
                print("❌ Failed to calculate 6M cutoff date")
                return sortedPayslips
            }
            let filtered = sortedPayslips.filter { createDateFromPayslip($0) >= cutoffDate }
            print("✅ 6M filter: \(filtered.count) out of \(sortedPayslips.count) payslips (from \(DateFormatter().string(from: cutoffDate)))")
            return filtered
            
        case .lastYear:
            // Calculate 12 months back from the latest payslip month
            guard let cutoffDate = calendar.date(byAdding: .month, value: -11, to: latestPayslipDate) else {
                print("❌ Failed to calculate 1Y cutoff date")
                return sortedPayslips
            }
            let filtered = sortedPayslips.filter { createDateFromPayslip($0) >= cutoffDate }
            print("✅ 1Y filter: \(filtered.count) out of \(sortedPayslips.count) payslips (from \(DateFormatter().string(from: cutoffDate)))")
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
                FintechColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Time range picker - Controls entire screen data
                        timeRangePickerSection
                        
                        // Enhanced integrated financial overview with charts
                        enhancedFinancialOverviewSection
                        
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
                print("🔍 InsightsView onAppear: Refreshing with \(filteredPayslips.count) filtered payslips")
                viewModel.refreshData(payslips: filteredPayslips)
            }
            .onChange(of: selectedTimeRange) {
                print("🔍 InsightsView time range changed to \(selectedTimeRange): Refreshing with \(filteredPayslips.count) filtered payslips")
                // Update view model when time range changes
                viewModel.refreshData(payslips: filteredPayslips)
            }
        }
    }
    
    // MARK: - Enhanced Financial Overview Section
    
    private var enhancedFinancialOverviewSection: some View {
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
                    
                    Text(viewModel.lastUpdated)
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
                    
                    Text("₹\(Formatters.formatIndianCurrency(viewModel.totalIncome))")
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
                    
                    Text("₹\(Formatters.formatIndianCurrency(viewModel.totalDeductions))")
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
                            Text("₹\(Formatters.formatIndianCurrency(viewModel.netIncome))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(FintechColors.getAccessibleColor(for: viewModel.netIncome, isPositive: viewModel.netIncome >= 0))
                            
                            // Add trend indicator here if available from ViewModel
                            if viewModel.netIncomeTrend != 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: viewModel.netIncomeTrend > 0 ? "arrow.up" : "arrow.down")
                                        .font(.caption)
                                        .foregroundColor(viewModel.netIncomeTrend > 0 ? FintechColors.successGreen : FintechColors.dangerRed)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Average Remittance")
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                        
                        Text("₹\(Formatters.formatIndianCurrency(viewModel.averageNetRemittance))")
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
                        value: viewModel.totalIncome,
                        color: FintechColors.successGreen
                    )
                    
                    QuickStatCard(
                        title: "Debits", 
                        value: viewModel.totalDeductions,
                        color: FintechColors.dangerRed
                    )
                }
            }
        }
        .fintechCardStyle()
    }
    
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
    
    // MARK: - Key Insights Section
    
    private var keyInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            VStack(spacing: 16) {
                // Earnings Section
                if !viewModel.earningsInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(FintechColors.successGreen)
                                .font(.caption)
                            
                            Text("Earnings")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(FintechColors.textPrimary)
                        }
                        .padding(.horizontal, 4)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.earningsInsights, id: \.title) { insight in
                                ClickableInsightCard(insight: insight)
                            }
                        }
                    }
                }
                
                // Subtle divider between sections
                if !viewModel.earningsInsights.isEmpty && !viewModel.deductionsInsights.isEmpty {
                    Divider()
                        .background(FintechColors.divider.opacity(0.3))
                        .padding(.vertical, 4)
                }
                
                // Deductions Section
                if !viewModel.deductionsInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(FintechColors.warningAmber)
                                .font(.caption)
                            
                            Text("Deductions")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(FintechColors.textPrimary)
                        }
                        .padding(.horizontal, 4)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.deductionsInsights, id: \.title) { insight in
                                ClickableInsightCard(insight: insight)
                            }
                        }
                    }
                }
            }
        }
        .fintechCardStyle()
    }
    
    // MARK: - Detailed Analysis Section
    
    private var detailedAnalysisSection: some View {
        VStack(spacing: 16) {
            // Top earnings/deductions
            topCategoriesCard
        }
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
                    .font(.system(size: 18, weight: .medium))
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
                
                Text("\(percentage, specifier: "%.1f")% of \(isIncome ? "credits" : "deductions")")
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



