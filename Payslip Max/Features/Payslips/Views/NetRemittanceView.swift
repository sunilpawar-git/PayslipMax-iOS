import SwiftUI

/// A view for displaying the net remittance amount
struct NetRemittanceView: View {
    let totalEarnings: Double
    let totalDeductions: Double
    
    var netAmount: Double {
        totalEarnings - totalDeductions
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Net Remittance")
                .font(.headline)
            
            HStack {
                Text("₹\(formatCurrency(netAmount))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            Text("(\(amountInWords(netAmount)) only)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
    
    private func amountInWords(_ amount: Double) -> String {
        // Simple implementation - in a real app, you'd want a more comprehensive converter
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        
        let integerPart = Int(amount)
        return formatter.string(from: NSNumber(value: integerPart))?.capitalized ?? ""
    }
} 