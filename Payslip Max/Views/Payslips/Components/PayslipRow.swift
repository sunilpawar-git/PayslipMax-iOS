import SwiftUI

struct PayslipRow: View {
    let payslip: any PayslipItemProtocol
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(payslip.month) \(payslip.year)")
                .font(.headline)
            
            HStack {
                Text("Credits: ₹\(payslip.credits, specifier: "%.2f")")
                Spacer()
                Text("Debits: ₹\(payslip.debits, specifier: "%.2f")")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
} 