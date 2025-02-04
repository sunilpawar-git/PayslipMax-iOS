import SwiftUI
import Charts

struct CreditsDebitsChartView: View {
    let credits: [Double]
    let debits: [Double]
    let labels: [String]
    
    var body: some View {
        Chart {
            ForEach(Array(zip(credits.indices, credits)), id: \.0) { index, credit in
                BarMark(
                    x: .value("Month", labels[index]),
                    y: .value("Amount", credit)
                )
                .foregroundStyle(.green)
            }
            
            ForEach(Array(zip(debits.indices, debits)), id: \.0) { index, debit in
                BarMark(
                    x: .value("Month", labels[index]),
                    y: .value("Amount", -debit)
                )
                .foregroundStyle(.red)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    let amount = value.as(Double.self) ?? 0
                    Text("₹\(abs(amount), specifier: "%.2f")")
                }
            }
        }
    }
} 