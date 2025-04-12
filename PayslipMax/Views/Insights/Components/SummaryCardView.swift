import SwiftUI

struct SummaryCard: View {
    let title: String
    let value: String
    let trend: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(trend > 0 ? "+\(String(format: "%.1f", trend))%" : "\(String(format: "%.1f", trend))%")
                    .font(.caption)
                    .foregroundColor(trend > 0 ? .green : trend < 0 ? .red : .primary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 160, height: 120)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    SummaryCard(
        title: "Total Income",
        value: "₹50,000",
        trend: 5.2,
        icon: "arrow.up.right",
        color: .green
    )
} 