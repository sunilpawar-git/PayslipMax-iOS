import SwiftUI

/// Card showing DSOP + AGIF as "Future Wealth" investment returns
/// Reframes these deductions as money going toward user's future wealth
struct InvestmentReturnsCard: View {
    let dsop: Double
    let agif: Double
    
    var investmentReturns: Double {
        return dsop + agif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Investment Returns")
                        .font(.headline)
                    
                    Text("Money building your future wealth")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Total Investment
            VStack(alignment: .leading, spacing: 8) {
                Text("₹\(investmentReturns, specifier: "%.0f")")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                
                Text("This month's contribution")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Breakdown
            VStack(spacing: 12) {
                investmentRow(
                    icon: "building.columns",
                    label: "DSOP",
                    description: "Provident Fund",
                    amount: dsop
                )
                
                investmentRow(
                    icon: "shield.checkered",
                    label: "AGIF",
                    description: "Insurance Fund",
                    amount: agif
                )
            }
            
            // Insight
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("These aren't lost money – they're your future security!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    // MARK: - Investment Row
    
    private func investmentRow(
        icon: String,
        label: String,
        description: String,
        amount: Double
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("₹\(amount, specifier: "%.0f")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        InvestmentReturnsCard(
            dsop: 40000,
            agif: 12500
        )
        .padding()
        
        Spacer()
    }
}

