import SwiftUI
import Charts

struct InsightsChartView: View {
    let chartData: [ChartData]
    let legendItems: [LegendItem]
    let selectedChartType: ChartType
    
    var body: some View {
        VStack(spacing: 16) {
            if chartData.isEmpty {
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
            } else {
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(chartData) { item in
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
                            }
                        }
                    }
                    .frame(height: 250)
                } else {
                    // Fallback for iOS 15
                    Text("Charts require iOS 16 or later")
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Legend
            HStack(spacing: 16) {
                ForEach(legendItems, id: \.label) { item in
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