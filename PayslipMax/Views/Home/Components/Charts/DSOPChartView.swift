import SwiftUI
import Charts

struct DSOPChartView: View {
    let items: [PayslipItem]
    
    var body: some View {
        Chart(items.prefix(6), id: \.id) { item in
            BarMark(
                x: .value("Month", item.month),
                y: .value("Balance", item.dsop)
            )
            .foregroundStyle(Color.green)
        }
        .frame(height: 200)
    }
} 