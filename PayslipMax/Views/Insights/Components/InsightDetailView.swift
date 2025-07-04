import SwiftUI
import Charts

struct InsightDetailView: View {
    let insight: InsightItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header section
                    headerSection
                    
                    // Chart visualization
                    if insight.detailItems.count > 1 {
                        chartSection
                    }
                    
                    // Detailed list
                    detailListSection
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(FintechColors.appBackground)
            .navigationTitle("Key Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon and title
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(insight.color.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: insight.detailType.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(insight.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    Text(insight.detailType.subtitle)
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                }
                
                Spacer()
            }
            
            // Summary stats
            summaryStatsSection
        }
        .fintechCardStyle()
    }
    
    // MARK: - Summary Stats
    
    private var summaryStatsSection: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Total",
                value: "₹\(Formatters.formatIndianCurrency(totalValue))",
                color: insight.color
            )
            
            if insight.detailItems.count > 1 {
                StatCard(
                    title: "Average",
                    value: "₹\(Formatters.formatIndianCurrency(averageValue))",
                    color: FintechColors.primaryBlue
                )
                
                StatCard(
                    title: "Periods",
                    value: "\(insight.detailItems.count)",
                    color: FintechColors.textSecondary
                )
            }
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trend Analysis")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            Chart(Array(insight.detailItems.enumerated()), id: \.element.id) { index, item in
                BarMark(
                    x: .value("Period", index + 1),
                    y: .value("Amount", item.value)
                )
                .foregroundStyle(insight.color.gradient)
                .cornerRadius(6)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("₹\(Formatters.formatCompactCurrency(amount))")
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let index = value.as(Int.self) {
                            Text("\(index)")
                        }
                    }
                    AxisGridLine()
                }
            }
            
            // Legend explanation
            Text("Numbers correspond to periods listed below")
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)
                .padding(.top, 8)
        }
        .fintechCardStyle()
    }
    
    // MARK: - Detail List Section
    
    private var detailListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Breakdown")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(sortedDetailItems.enumerated()), id: \.element.id) { index, item in
                    DetailItemRow(item: item, color: insight.color, index: index + 1)
                }
            }
        }
        .fintechCardStyle()
    }
    
    // MARK: - Helper Properties
    
    private var totalValue: Double {
        insight.detailItems.reduce(0) { $0 + $1.value }
    }
    
    private var averageValue: Double {
        guard !insight.detailItems.isEmpty else { return 0 }
        return totalValue / Double(insight.detailItems.count)
    }
    
    private var sortedDetailItems: [InsightDetailItem] {
        insight.detailItems.sorted { $0.value > $1.value }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct DetailItemRow: View {
    let item: InsightDetailItem
    let color: Color
    let index: Int
    
    var body: some View {
        HStack {
            // Numeric indicator circle
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(index)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.period)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)
                
                if let additionalInfo = item.additionalInfo {
                    Text(additionalInfo)
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }
            
            Spacer()
            
            Text("₹\(Formatters.formatIndianCurrency(item.value))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
    }
}

#Preview {
    InsightDetailView(
        insight: InsightItem(
            title: "Highest Income",
            description: "Your highest income was in April 2025",
            iconName: "arrow.up.circle.fill",
            color: .green,
            detailItems: [
                InsightDetailItem(period: "April 2025", value: 318593, additionalInfo: "Highest month"),
                InsightDetailItem(period: "March 2025", value: 295000, additionalInfo: nil),
                InsightDetailItem(period: "February 2025", value: 280000, additionalInfo: nil)
            ],
            detailType: .monthlyIncomes
        )
    )
} 