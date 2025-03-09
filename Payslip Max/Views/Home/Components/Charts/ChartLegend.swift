import SwiftUI

struct ChartLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            ChartLegendItem(color: .green, label: "Credits")
            ChartLegendItem(color: .red, label: "Debits")
        }
        .padding(.horizontal)
    }
}

struct ChartLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 