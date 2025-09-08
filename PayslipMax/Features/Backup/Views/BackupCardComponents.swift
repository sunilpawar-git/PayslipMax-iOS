import SwiftUI

// MARK: - Backup Card Component

struct BackupCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let actionTitle: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Icon and Title
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Action Button
            Button(action: action) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }

                    Text(isLoading ? "Processing..." : actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(iconColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isLoading)
        }
        .padding(16)
        .background(FintechColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: FintechColors.shadow, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct BackupCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BackupCard(
                icon: "square.and.arrow.up",
                iconColor: .blue,
                title: "Create Backup",
                subtitle: "Export all your payslip data to a secure backup file",
                actionTitle: "Export Now",
                isLoading: false
            ) {
                print("Export tapped")
            }

            BackupCard(
                icon: "square.and.arrow.down",
                iconColor: .green,
                title: "Import Data",
                subtitle: "Restore payslips from a backup file",
                actionTitle: "Processing...",
                isLoading: true
            ) {
                print("Import tapped")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
#endif
