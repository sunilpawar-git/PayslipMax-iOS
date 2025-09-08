import SwiftUI

// MARK: - Backup Statistics View

struct BackupStatsView: View {
    let stats: BackupStats

    var body: some View {
        VStack(spacing: 16) {
            Text("Backup Statistics")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                BackupStatCard(
                    title: "Total Backups",
                    value: "\(stats.totalBackups)",
                    icon: "square.and.arrow.up",
                    color: FintechColors.primaryBlue
                )

                BackupStatCard(
                    title: "Last Backup",
                    value: stats.lastBackupDate?.formatted(date: .abbreviated, time: .omitted) ?? "Never",
                    icon: "clock",
                    color: FintechColors.successGreen
                )

                BackupStatCard(
                    title: "Data Size",
                    value: formatFileSize(stats.totalDataSize),
                    icon: "externaldrive",
                    color: FintechColors.warningAmber
                )

                BackupStatCard(
                    title: "Payslips",
                    value: "\(stats.totalPayslips)",
                    icon: "doc.text",
                    color: FintechColors.primaryBlue
                )
            }
        }
        .padding(16)
        .background(FintechColors.cardBackground)
        .cornerRadius(12)
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct BackupStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(FintechColors.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Data Types

struct BackupStats {
    let totalBackups: Int
    let lastBackupDate: Date?
    let totalDataSize: Int
    let totalPayslips: Int
}
