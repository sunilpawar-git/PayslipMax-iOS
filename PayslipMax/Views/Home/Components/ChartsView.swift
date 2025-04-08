import SwiftUI
import Charts

// Define PayslipChartData here instead of importing it
struct PayslipChartData: Identifiable {
    let id = UUID()
    let month: String
    let credits: Double
    let debits: Double
    let net: Double
}

/// A view for displaying financial charts
struct ChartsView: View {
    let data: [PayslipChartData]
    
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
    }
    
    // Fallback chart view for iOS 15
    private var legacyChartView: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 8) {
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
    
    private var maxValue: Double {
        data.map { $0.credits }.max() ?? 1.0
    }
}

#Preview {
    ChartsView(data: [
        PayslipChartData(month: "Jan", credits: 50000, debits: 30000, net: 20000),
        PayslipChartData(month: "Feb", credits: 60000, debits: 35000, net: 25000),
        PayslipChartData(month: "Mar", credits: 55000, debits: 32000, net: 23000)
    ])
} 