import SwiftUI

// MARK: - Benchmark Comparison Card

struct BenchmarkCard: View {
    let benchmark: BenchmarkData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(categoryText)
                    .font(.headline)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                Text("\(Int(benchmark.percentile))th percentile")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FintechColors.primaryBlue.opacity(0.15))
                    .foregroundColor(FintechColors.primaryBlue)
                    .cornerRadius(8)
            }
            
            // Comparison visualization
            VStack(spacing: 8) {
                HStack {
                    Text("You")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    Spacer()
                    Text("Industry Average")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
                
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(FintechColors.primaryBlue)
                            .frame(width: geometry.size.width * min(benchmark.userValue / benchmark.benchmarkValue, 1.0))
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: geometry.size.width * max(0, 1.0 - min(benchmark.userValue / benchmark.benchmarkValue, 1.0)))
                    }
                }
                .frame(height: 8)
                .cornerRadius(4)
                
                // Value comparison
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Value")
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                        Text("₹\(formatBenchmarkValue(benchmark.userValue))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Industry Avg")
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                        Text("₹\(formatBenchmarkValue(benchmark.benchmarkValue))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)
                    }
                }
                
                Text(benchmark.comparison.displayDescription)
                    .font(.subheadline)
                    .foregroundColor(comparisonColor)
                    .fontWeight(.medium)
            }
            
            // Performance indicator
            VStack(alignment: .leading, spacing: 8) {
                Text("Performance Insight")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Text(getInsightText())
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.1))
            )
        }
        .fintechCardStyle()
    }
    
    private var categoryText: String {
        switch benchmark.category {
        case .salary: return "Annual Salary"
        case .taxRate: return "Tax Rate"
        case .savingsRate: return "Savings Rate"
        case .benefits: return "Benefits"
        case .growthRate: return "Growth Rate"
        case .totalCompensation: return "Total Compensation"
        }
    }
    
    private var comparisonColor: Color {
        switch benchmark.comparison {
        case .aboveAverage: return .green
        case .average: return .gray
        case .belowAverage: return .orange
        }
    }
    
    private func formatBenchmarkValue(_ value: Double) -> String {
        if benchmark.category == .taxRate || benchmark.category == .savingsRate || benchmark.category == .growthRate {
            return String(format: "%.1f%%", value)
        } else if value >= 100000 {
            return String(format: "%.1fL", value / 100000)
        } else if value >= 1000 {
            return String(format: "%.1fK", value / 1000)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    private func getInsightText() -> String {
        switch benchmark.comparison {
        case .aboveAverage:
            return "You're performing well compared to industry standards. Keep up the good work!"
        case .average:
            return "You're performing at industry average. Consider strategies for improvement."
        case .belowAverage:
            return "There's room for improvement. Consider reviewing your approach in this area."
        }
    }
}

// MARK: - Benchmark Data Extension

extension BenchmarkData.ComparisonResult {
    var displayDescription: String {
        switch self {
        case .aboveAverage(let percentage):
            return "You're performing \(String(format: "%.1f", percentage))% above industry average"
        case .average:
            return "You're in line with industry average"
        case .belowAverage(let percentage):
            return "You're \(String(format: "%.1f", percentage))% below industry average"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        BenchmarkCard(benchmark: BenchmarkData(
            category: .salary,
            userValue: 850000,
            benchmarkValue: 750000,
            percentile: 75,
            comparison: .aboveAverage(13.3)
        ))
        
        BenchmarkCard(benchmark: BenchmarkData(
            category: .savingsRate,
            userValue: 15.5,
            benchmarkValue: 20.0,
            percentile: 40,
            comparison: .belowAverage(22.5)
        ))
    }
    .padding()
} 