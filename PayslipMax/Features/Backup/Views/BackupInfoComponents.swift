import SwiftUI

// MARK: - Backup Info View

struct BackupInfoView: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(FintechColors.successGreen)
                            .frame(width: 12, height: 12)
                            .padding(.top, 2)

                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(FintechColors.cardBackground.opacity(0.5))
        .cornerRadius(12)
    }
}
