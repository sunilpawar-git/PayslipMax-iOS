import SwiftUI
import Charts

struct IncomeTaxChartView: View {
    let items: [PayslipItem]
    
    var body: some View {
        Chart(items.prefix(6), id: \.id) { item in
            BarMark(
                x: .value("Month", item.month),
                y: .value("Tax", item.tax)
            )
            .foregroundStyle(Color.orange)
        }
        .frame(height: 200)
    }
} 