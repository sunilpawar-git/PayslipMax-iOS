import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers

/// Wrapper view that handles backup service initialization
struct BackupViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var backupService: BackupService?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let backupService = backupService {
                BackupViewSimplified(backupService: backupService)
            } else {
                errorView
            }
        }
        .task {
            await createBackupService()
        }
    }
    
    @MainActor
    private func createBackupService() async {
        do {
            // Create dependencies manually
            let securityService = SecurityServiceImpl()
            try await securityService.initialize()
            
            let dataService = DataServiceImpl(securityService: securityService, modelContext: modelContext)
            try await dataService.initialize()
            
            let secureDataManager = SecureDataManager()
            
            // Create backup service
            let service = BackupService(
                dataService: dataService,
                secureDataManager: secureDataManager,
                modelContext: modelContext
            )
            
            backupService = service
            isLoading = false
        } catch {
            print("Failed to create BackupService: \(error)")
            isLoading = false
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initializing Backup Service...")
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)
        }
        .padding()
        .background(FintechColors.appBackground)
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(FintechColors.dangerRed)
            
            Text("Service Unavailable")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(FintechColors.textPrimary)
            
            Text("Backup service could not be initialized. Please try again later.")
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(FintechColors.appBackground)
    }
}

/// Simplified backup view without the complex tab interface
struct BackupViewSimplified: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var backupService: BackupService
    @StateObject private var qrCodeService = QRCodeService()
    
    // UI State
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingFilePicker = false
    @State private var showingShareSheet = false
    @State private var showingSuccess = false
    @State private var showingError = false
    
    // Results
    @State private var exportResult: BackupExportResult?
    @State private var importResult: BackupImportResult?
    @State private var errorMessage = ""
    
    // Import settings
    @State private var importStrategy: ImportStrategy = .skipDuplicates
    
    init(backupService: BackupService) {
        self._backupService = StateObject(wrappedValue: backupService)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                FintechColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Unified Export Section
                        unifiedExportSection
                        
                        // Unified Import Section  
                        unifiedImportSection
                        
                        // Pro Feature Info
                        proFeatureInfo
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Backup & Restore")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Close") {
                    dismiss()
                }
            )
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json, .data, .item, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showingShareSheet, content: shareSheetView)
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "icloud.and.arrow.up")
                .font(.system(size: 40))
                .foregroundColor(FintechColors.primaryBlue)
            
            Text("Cloud Backup")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(FintechColors.textPrimary)
            
            Text("Export your data to any cloud service and restore it on any device")
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Unified Export Section
    
    private var unifiedExportSection: some View {
        VStack(spacing: 16) {
            Text("Export Data")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                // Export Action Area
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 24))
                            .foregroundColor(FintechColors.primaryBlue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Create Backup File")
                                .font(.headline)
                                .foregroundColor(FintechColors.textPrimary)
                            
                            Text("Export all payslips to a secure, encrypted backup file")
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
                                Text("Exporting...")
                            } else {
                                Text("Export Now")
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
                
                // Export Results (if available)
                if let result = exportResult {
                    Divider()
                        .background(FintechColors.textSecondary.opacity(0.3))
                    
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
            }
            .padding(16)
            .background(FintechColors.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Unified Import Section
    
    private var unifiedImportSection: some View {
        VStack(spacing: 16) {
            Text("Import Data")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                // Import Strategy Selection
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
                            Button(action: { importStrategy = strategy }) {
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
                
                Divider()
                    .background(FintechColors.textSecondary.opacity(0.3))
                
                // Import File Selection
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
                            if isImporting {
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
                    .disabled(isImporting)
                }
                
                // Import Results (if available)
                if let result = importResult {
                    Divider()
                        .background(FintechColors.textSecondary.opacity(0.3))
                    
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
            }
            .padding(16)
            .background(FintechColors.cardBackground)
            .cornerRadius(12)
        }
    }
    

    
    // MARK: - Pro Feature Info
    
    private var proFeatureInfo: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(FintechColors.warningAmber)
                
                Text("Pro Feature")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Backup works with ANY cloud service")
                Text("• Secure encryption protects your data")
                Text("• Easy device switching and data migration")
                Text("• Works offline - no internet required for parsing")
            }
            .font(.subheadline)
            .foregroundColor(FintechColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(FintechColors.warningAmber.opacity(0.1))
        .cornerRadius(12)
    }
    

    
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
    
    // MARK: - Helper Methods
    
    private func exportData() {
        isExporting = true
        
        Task {
            do {
                let result = try await backupService.exportBackup()
                
                await MainActor.run {
                    exportResult = result
                    isExporting = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExporting = false
                    showingError = true
                }
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            print("File picker returned \(urls.count) URLs")
            guard let url = urls.first else { 
                print("No URLs returned from file picker")
                errorMessage = "No file was selected"
                showingError = true
                return 
            }
            print("Selected file URL: \(url)")
            importFromFile(url)
        case .failure(let error):
            print("File picker failed with error: \(error)")
            errorMessage = "File selection failed: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func importFromFile(_ url: URL) {
        isImporting = true
        
        Task {
            // Start accessing the security-scoped resource
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                // Make sure to release the security-scoped resource when finished
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                print("Attempting to import from URL: \(url)")
                print("URL path: \(url.path)")
                print("URL absolute string: \(url.absoluteString)")
                
                // Check file existence using the proper path method
                let filePath = url.path
                guard FileManager.default.fileExists(atPath: filePath) else {
                    print("File does not exist at path: \(filePath)")
                    throw BackupError.fileNotFound
                }
                
                // Check if we can access the file
                guard FileManager.default.isReadableFile(atPath: filePath) else {
                    print("File is not readable at path: \(filePath)")
                    throw BackupError.importFailed("File is not readable")
                }
                
                // Try to get file attributes first to check permissions
                let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
                let fileSize = attributes[.size] as? NSNumber ?? 0
                print("Reading backup file: \(url.lastPathComponent), size: \(fileSize) bytes")
                
                // Validate file size
                guard fileSize.intValue > 0 else {
                    print("File is empty")
                    throw BackupError.importFailed("Selected file is empty")
                }
                
                // Read the file data - try multiple approaches if needed
                let data: Data
                do {
                    // First try direct read
                    data = try Data(contentsOf: url)
                    print("Successfully read \(data.count) bytes from backup file")
                } catch let readError {
                    print("Direct read failed: \(readError)")
                    
                    // If direct read fails, try copying to app's documents directory first
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let tempURL = documentsDirectory.appendingPathComponent("temp_\(UUID().uuidString)_\(url.lastPathComponent)")
                    
                    do {
                        // Remove existing file if it exists
                        try? FileManager.default.removeItem(at: tempURL)
                        
                        // Copy file to app's directory
                        try FileManager.default.copyItem(at: url, to: tempURL)
                        print("Copied file to temp location: \(tempURL.path)")
                        
                        // Read from copied file
                        data = try Data(contentsOf: tempURL)
                        print("Successfully read \(data.count) bytes from copied file")
                        
                        // Clean up
                        try? FileManager.default.removeItem(at: tempURL)
                    } catch let copyError {
                        print("Copy approach also failed: \(copyError)")
                        throw BackupError.importFailed("Unable to read file: \(readError.localizedDescription)")
                    }
                }
                
                // Validate data
                guard data.count > 0 else {
                    throw BackupError.importFailed("File contains no data")
                }
                
                print("About to import \(data.count) bytes of backup data")
                
                // Import the backup
                let result = try await backupService.importBackup(from: data, strategy: importStrategy)
                
                await MainActor.run {
                    importResult = result
                    isImporting = false
                    showingSuccess = true
                    print("Import completed successfully: \(result.summary.successfulImports) payslips imported")
                }
            } catch {
                await MainActor.run {
                    let errorMsg = "Import failed: \(error.localizedDescription)"
                    errorMessage = errorMsg
                    print("Backup import error: \(error)")
                    isImporting = false
                    showingError = true
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
    
    private var successMessage: String {
        if exportResult != nil {
            return "Backup created successfully! You can now save it to any cloud service."
        } else if let result = importResult {
            return "Import completed! \(result.summary.successfulImports) payslips imported successfully."
        }
        return "Operation completed successfully!"
    }
}

extension ImportStrategy {
    var title: String {
        switch self {
        case .replaceAll: return "Replace All Data"
        case .skipDuplicates: return "Skip Duplicates (Recommended)"
        case .mergeUpdates: return "Merge Updates"
        case .askUser: return "Ask Each Time"
        }
    }
    
    var description: String {
        switch self {
        case .replaceAll: return "Clear all existing data and import from backup"
        case .skipDuplicates: return "Only import payslips that don't already exist"
        case .mergeUpdates: return "Update existing payslips with newer data"
        case .askUser: return "Ask for each conflicting payslip"
        }
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