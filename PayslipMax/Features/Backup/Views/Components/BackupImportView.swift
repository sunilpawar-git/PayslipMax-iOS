import SwiftUI
import UniformTypeIdentifiers

/// Import functionality component for backup feature
struct BackupImportView: View {
    @ObservedObject var backupService: BackupService
    @StateObject private var importLogic: BackupImportLogicHandler

    @State private var showingFilePicker = false
    @State private var importStrategy: ImportStrategy = .skipDuplicates

    init(backupService: BackupService, onError: @escaping (String) -> Void, onSuccess: @escaping () -> Void) {
        self.backupService = backupService
        self._importLogic = StateObject(wrappedValue: BackupImportLogicHandler(backupService: backupService, onError: onError, onSuccess: onSuccess))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Import Data")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                // Import Strategy Selection
                importStrategySection

                Divider()
                    .background(FintechColors.textSecondary.opacity(0.3))

                // Import File Selection
                importFileSection

                // Import Results (if available)
                if let result = importLogic.importResult {
                    Divider()
                        .background(FintechColors.textSecondary.opacity(0.3))

                    importResultsView(result)
                }
            }
            .padding(16)
            .background(FintechColors.cardBackground)
            .cornerRadius(12)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json, .data, .item, .plainText],
            allowsMultipleSelection: false
        ) { result in
            importLogic.handleFileImport(result)
        }
        .sheet(isPresented: $importLogic.showingConfirmation) {
            importConfirmationView
        }
    }

    // MARK: - Import Confirmation View

    private var importConfirmationView: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let backup = importLogic.previewBackupFile {
                    // Header Icon
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 48))
                        .foregroundColor(FintechColors.primaryBlue)
                        .padding(.top, 20)

                    Text("Preview Import")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(FintechColors.textPrimary)

                    // Backup Details Card
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

                    // Strategy Reminder
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

                    // Action Buttons
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

    private func detailRow(icon: String, title: String, value: String) -> some View {
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Import Strategy Section

    private var importStrategySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(FintechColors.primaryBlue)

                Text("Step 1: Import Strategy")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)

                Spacer()
            }

            VStack(spacing: 8) {
                ForEach([ImportStrategy.skipDuplicates, .replaceAll], id: \.self) { strategy in
                    Button(action: {
                        importStrategy = strategy
                        importLogic.updateStrategy(strategy)
                    }) {
                        HStack {
                            Image(systemName: importStrategy == strategy ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(importStrategy == strategy ? FintechColors.primaryBlue : FintechColors.textSecondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(strategy.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(FintechColors.textPrimary)

                                Text(strategy.description)
                                    .font(.caption)
                                    .foregroundColor(FintechColors.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    // MARK: - Import File Section

    private var importFileSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 24))
                    .foregroundColor(FintechColors.successGreen)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Step 2: Select Backup")
                        .font(.headline)
                        .foregroundColor(FintechColors.textPrimary)

                    Text("Choose a backup file to restore your data")
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                }

                Spacer()
            }

            Button(action: { showingFilePicker = true }) {
                HStack {
                    if importLogic.isImporting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                        Text("Importing...")
                    } else {
                        Image(systemName: "folder")
                        Text("Choose Backup File")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(FintechColors.successGreen)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(importLogic.isImporting)
        }
    }

    // MARK: - Import Results View

    private func importResultsView(_ result: BackupImportResult) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(result.wasSuccessful ? FintechColors.successGreen : FintechColors.warningAmber)
                Text("Import Complete")
                    .font(.headline)
                    .foregroundColor(result.wasSuccessful ? FintechColors.successGreen : FintechColors.warningAmber)
                Spacer()
            }

            VStack(spacing: 8) {
                resultRow("Imported:", "\(result.summary.successfulImports)")
                resultRow("Skipped:", "\(result.summary.skippedDuplicates)")
                if result.summary.failedImports > 0 {
                    resultRow("Failed:", "\(result.summary.failedImports)")
                }
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

}
