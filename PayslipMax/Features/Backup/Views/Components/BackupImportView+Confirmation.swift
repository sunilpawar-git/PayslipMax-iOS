import SwiftUI

// MARK: - Import Confirmation View

extension BackupImportView {

    var importConfirmationView: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let backup = importLogic.previewBackupFile {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 48))
                        .foregroundColor(FintechColors.primaryBlue)
                        .padding(.top, 20)

                    Text("Preview Import")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(FintechColors.textPrimary)

                    VStack(spacing: 16) {
                        detailRow(icon: "calendar", title: "Export Date", value: formatDate(backup.exportDate))
                        detailRow(icon: "iphone", title: "Device", value: backup.deviceId)
                        detailRow(icon: "doc.text.fill", title: "Payslips", value: "\(backup.payslips.count)")
                        detailRow(icon: "lock.fill", title: "Encryption", value: "Ver 1")
                    }
                    .padding()
                    .background(FintechColors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(FintechColors.textSecondary.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    VStack(spacing: 8) {
                        Text("Selected Strategy")
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                            .textCase(.uppercase)

                        Text(importStrategy.title)
                            .font(.headline)
                            .foregroundColor(FintechColors.primaryBlue)
                    }
                    .padding(.top, 8)

                    Spacer()

                    VStack(spacing: 12) {
                        Button(action: { importLogic.confirmImport() }) {
                            Text("Import Backup")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(FintechColors.successGreen)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button(action: { importLogic.cancelImport() }) {
                            Text("Cancel")
                                .fontWeight(.medium)
                                .foregroundColor(FintechColors.textSecondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                } else {
                    ProgressView()
                }
            }
            .navigationBarHidden(true)
            .background(FintechColors.appBackground.edgesIgnoringSafeArea(.all))
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Confirmation Helpers

    func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(FintechColors.textSecondary)
                .frame(width: 24)

            Text(title)
                .foregroundColor(FintechColors.textSecondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .foregroundColor(FintechColors.textPrimary)
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
