import SwiftUI

/// A section that displays a category of pay items
struct CategorySection: View {
    let title: String
    let items: [PayItem]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ForEach(items) { item in
                HStack {
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    Text("₹\(CurrencyFormatter.format(item.amount))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(alignment: .trailing)
                }
            }

            Divider()
                .padding(.vertical, 4)
        }
    }
}
