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
    }
    
    // MARK: - Import Strategy Section
    
    private var importStrategySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(FintechColors.primaryBlue)
                
                Text("Import Strategy")
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
                    Text("Import from File")
                        .font(.headline)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    Text("Select a backup file from your cloud storage or device")
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
                        Text("Choose File")
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