import SwiftUI

/// Export functionality component for backup feature
struct BackupExportView: View {
    @ObservedObject var backupService: BackupService

    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportResult: BackupExportResult?

    let onError: (String) -> Void
    let onSuccess: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Export Data")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                // Export Action Area
                exportActionArea

                // Export Results (if available)
                if let result = exportResult {
                    Divider()
                        .background(FintechColors.textSecondary.opacity(0.3))

                    exportResultsView(result)
                }
            }
            .padding(16)
            .background(FintechColors.cardBackground)
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingShareSheet, content: shareSheetView)
    }

    // MARK: - Export Action Area

    private var exportActionArea: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 24))
                    .foregroundColor(FintechColors.primaryBlue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Save all your payslips as an encrypted backup file")
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                }

                Spacer()
            }

            Button(action: { exportData() }) {
                HStack {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                        Text("Creating...")
                    } else {
                        Text("Create Backup")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(FintechColors.primaryBlue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isExporting)
        }
    }

    // MARK: - Export Results View

    private func exportResultsView(_ result: BackupExportResult) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(FintechColors.successGreen)
                Text("Export Complete")
                    .font(.headline)
                    .foregroundColor(FintechColors.successGreen)
                Spacer()
            }

            VStack(spacing: 8) {
                resultRow("Payslips Exported:", "\(result.summary.totalPayslips)")
                resultRow("File Size:", result.summary.fileSizeFormatted)
                resultRow("Encryption:", "Enabled")
            }

            Button(action: { showingShareSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Backup File")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(FintechColors.successGreen)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Helper Views

    private func resultRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(FintechColors.textPrimary)
        }
    }

    // MARK: - Share Sheet

    private func shareSheetView() -> some View {
        Group {
            if let result = exportResult {
                ActivityView(activityItems: [
                    createShareableFile(from: result)
                ])
            } else {
                Text("No data to share")
            }
        }
    }

    // MARK: - Export Logic

    private func exportData() {
        isExporting = true

        Task {
            do {
                let result = try await backupService.exportBackup()

                await MainActor.run {
                    exportResult = result
                    isExporting = false
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    onError(error.localizedDescription)
                }
            }
        }
    }

    private func createShareableFile(from result: BackupExportResult) -> URL {
        // Use a temporary directory that's accessible for sharing
        let tempDirectory = FileManager.default.temporaryDirectory
        var fileURL = tempDirectory.appendingPathComponent(result.filename)

        do {
            // Remove existing file if it exists
            try? FileManager.default.removeItem(at: fileURL)

            // Write the backup data
            try result.fileData.write(to: fileURL)
            print("Successfully wrote backup file to: \(fileURL.path)")

            // Set file attributes for iOS sharing compatibility
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true  // Temporary file, don't backup
            try fileURL.setResourceValues(resourceValues)

            // Ensure file permissions are correct for sharing
            try FileManager.default.setAttributes([
                .posixPermissions: 0o644  // Read/write for owner, read for others
            ], ofItemAtPath: fileURL.path)

        } catch {
            print("Failed to write backup file: \(error)")
            // Fallback to Documents directory if temp fails
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fallbackURL = documentsDirectory.appendingPathComponent(result.filename)

            do {
                try? FileManager.default.removeItem(at: fallbackURL)
                try result.fileData.write(to: fallbackURL)
                return fallbackURL
            } catch {
                print("Fallback also failed: \(error)")
            }
        }

        return fileURL
    }
}

// MARK: - Activity View for File Sharing

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
