import SwiftUI

struct FinancialSummaryView: View {
    let grossPay: Double
    let totalDeductions: Double
    let netPay: Double
    
    private var netPayPercent: Double {
        if grossPay > 0 {
            return (netPay / grossPay) * 100
        }
        return 0
    }
    
    var body: some View {
        PayslipSectionView(title: "Financial Summary") {
            VStack(spacing: 16) {
                SummaryRow(
                    label: "Gross Pay",
                    value: formatCurrency(grossPay),
                    color: .green
                )
                
                SummaryRow(
                    label: "Total Deductions",
                    value: formatCurrency(totalDeductions),
                    color: .red
                )
                
                Divider()
                
                HStack {
                    Text("Net Pay")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(formatCurrency(netPay))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(String(format: "%.1f", netPayPercent))% of gross")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        
        return formatter.string(from: NSNumber(value: value)) ?? "₹0"
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(color)
        }
    }
} 