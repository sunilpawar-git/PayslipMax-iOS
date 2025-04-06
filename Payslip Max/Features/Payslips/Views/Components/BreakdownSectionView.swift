import SwiftUI

struct BreakdownSectionView: View {
    let title: String
    let items: [(String, Double)]
    let totalLabel: String
    let totalValue: Double
    
    var body: some View {
        PayslipSectionView(title: title) {
            VStack(spacing: 12) {
                ForEach(items, id: \.0) { item in
                    HStack {
                        Text(item.0)
                            .font(.body)
                        
                        Spacer()
                        
                        Text(formatCurrency(item.1))
                            .font(.body)
                    }
                }
                
                if !items.isEmpty {
                    Divider()
                    
                    HStack {
                        Text(totalLabel)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text(formatCurrency(totalValue))
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                } else {
                    Text("No \(title.lowercased()) for this period")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
} 