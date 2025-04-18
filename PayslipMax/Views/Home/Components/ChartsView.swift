import SwiftUI
import Charts

// Define PayslipChartData here instead of importing it
struct PayslipChartData: Identifiable, Equatable {
    let id = UUID()
    let month: String
    let credits: Double
    let debits: Double
    let net: Double
    
    static func == (lhs: PayslipChartData, rhs: PayslipChartData) -> Bool {
        return lhs.month == rhs.month &&
               lhs.credits == rhs.credits &&
               lhs.debits == rhs.debits &&
               lhs.net == rhs.net
    }
}

/// A view for displaying financial charts
struct ChartsView: View {
    let data: [PayslipChartData]
    
    // Cache for expensive calculations
    @State private var maxValue: Double = 0
    @State private var chartDataPrepared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Financial Overview")
                .font(.headline)
                .padding(.bottom, 4)
            
            if #available(iOS 16.0, *) {
                chartView
                    .frame(height: 220)
                    .padding(.vertical)
            } else {
                // Fallback for iOS 15
                legacyChartView
                    .frame(height: 220)
                    .padding(.vertical)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            // Calculate max value only once when view appears
            prepareChartData()
        }
        .onChange(of: data) { _, _ in
            // Recalculate only when data changes
            prepareChartData()
        }
    }
    
    // Prepare chart data on a background thread to avoid UI stutter
    private func prepareChartData() {
        BackgroundQueue.shared.async {
            let maxVal = data.map { Swift.max($0.credits, $0.debits) }.max() ?? 1.0
            DispatchQueue.main.async {
                self.maxValue = maxVal
                self.chartDataPrepared = true
            }
        }
    }
    
    @available(iOS 16.0, *)
    private var chartView: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", item.credits),
                    width: .ratio(0.4)
                )
                .foregroundStyle(Color.green.gradient)
                .position(by: .value("Type", "Credits"))
                
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", item.debits),
                    width: .ratio(0.4)
                )
                .foregroundStyle(Color.red.gradient)
                .position(by: .value("Type", "Debits"))
            }
        }
        .chartLegend(position: .bottom)
        .equatable(ChartsContent(data: data))
    }
    
    // Fallback chart view for iOS 15
    private var legacyChartView: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 8) {
                // Check if data is ready to avoid division by zero
                if chartDataPrepared {
                    ForEach(data) { item in
                        VStack {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: (geometry.size.width - CGFloat(data.count) * 8) / CGFloat(data.count),
                                       height: CGFloat(item.credits) / CGFloat(maxValue) * geometry.size.height * 0.8)
                            
                            Text(item.month)
                                .font(.caption)
                                .frame(height: 20)
                        }
                    }
                } else {
                    // Show a placeholder until data is ready
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .equatable(ChartsContent(data: data))
    }
}

// Helper struct for equatable comparison
struct ChartsContent: Equatable {
    let data: [PayslipChartData]
    
    static func == (lhs: ChartsContent, rhs: ChartsContent) -> Bool {
        guard lhs.data.count == rhs.data.count else { return false }
        
        for (index, lhsItem) in lhs.data.enumerated() {
            let rhsItem = rhs.data[index]
            if lhsItem != rhsItem {
                return false
            }
        }
        
        return true
    }
}

#Preview {
    ChartsView(data: [
        PayslipChartData(month: "Jan", credits: 50000, debits: 30000, net: 20000),
        PayslipChartData(month: "Feb", credits: 60000, debits: 35000, net: 25000),
        PayslipChartData(month: "Mar", credits: 55000, debits: 32000, net: 23000)
    ])
} 