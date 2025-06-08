import SwiftUI
import Charts

struct InsightsChartView: View {
    let chartData: [ChartData]
    let legendItems: [LegendItem]
    let selectedChartType: ChartType
    
    var body: some View {
        VStack(spacing: 16) {
            if chartData.isEmpty {
                EmptyChartView()
            } else {
                // Chart content
                Group {
                    switch selectedChartType {
                    case .bar:
                        BarChartView(data: chartData)
                    case .line:
                        LineChartView(data: chartData)
                    }
                }
                .frame(height: 250)
                
                // Legend
                if !legendItems.isEmpty {
                    LegendView(items: legendItems)
                }
            }
        }
        .fintechCardStyle()
    }
}

struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 50))
                .foregroundColor(FintechColors.textSecondary)
            
            Text("No Data Available")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            Text("Add more payslips to see insights")
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
        .background(FintechColors.backgroundGray)
        .cornerRadius(12)
    }
}

struct BarChartView: View {
    let data: [ChartData]
    
    var body: some View {
        Chart(data, id: \.category) { item in
            BarMark(
                x: .value("Category", item.category),
                y: .value("Value", item.value)
            )
            .foregroundStyle(FintechColors.getCategoryColor(for: item.category))
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(FintechColors.textSecondary.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(FintechColors.textSecondary)
                AxisValueLabel()
                    .foregroundStyle(FintechColors.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(FintechColors.textSecondary.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(FintechColors.textSecondary)
                AxisValueLabel()
                    .foregroundStyle(FintechColors.textSecondary)
            }
        }
    }
}

struct LineChartView: View {
    let data: [ChartData]
    
    var body: some View {
        Chart(data, id: \.category) { item in
            LineMark(
                x: .value("Category", item.category),
                y: .value("Value", item.value)
            )
            .foregroundStyle(FintechColors.primaryBlue)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            PointMark(
                x: .value("Category", item.category),
                y: .value("Value", item.value)
            )
            .foregroundStyle(FintechColors.primaryBlue)
            .symbolSize(50)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(FintechColors.textSecondary.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(FintechColors.textSecondary)
                AxisValueLabel()
                    .foregroundStyle(FintechColors.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(FintechColors.textSecondary.opacity(0.3))
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(FintechColors.textSecondary)
                AxisValueLabel()
                    .foregroundStyle(FintechColors.textSecondary)
            }
        }
    }
}

struct LegendView: View {
    let items: [LegendItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 12, height: 12)
                        
                        Text(item.label)
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(FintechColors.backgroundGray)
        .cornerRadius(8)
    }
}

#Preview {
    InsightsChartView(
        chartData: [
            ChartData(label: "Jan", value: 5000, category: "Income"),
            ChartData(label: "Feb", value: 6000, category: "Income"),
            ChartData(label: "Mar", value: 7500, category: "Income")
        ], 
        legendItems: [
            LegendItem(label: "Income", color: .blue)
        ],
        selectedChartType: .bar
    )
} 