import SwiftUI

// Reference the InvestmentTipsData at the top level
struct InvestmentTipsView: View {
    // Use hardcoded tips here since we're having import issues
    // In a real app, we would use InvestmentTipsData.getTips()
    private let tips = [
        "Start investing early to benefit from compound interest over time",
        "Maintain an emergency fund of 3-6 months of expenses before investing",
        "Diversify your investments across different asset classes to reduce risk",
        "Consider tax-advantaged retirement accounts for long-term growth",
        "Regularly review and rebalance your investment portfolio"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Investment Tips")
                .font(.title3)
                .fontWeight(.semibold)
                .accessibilityIdentifier("tips_view")
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top) {
                        Text("•")
                            .font(.body)
                            .foregroundColor(.primary)
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)
                    .accessibilityIdentifier("tips_view")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}
