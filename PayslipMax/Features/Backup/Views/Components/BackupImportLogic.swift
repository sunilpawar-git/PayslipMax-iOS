import SwiftUI
import UniformTypeIdentifiers

/// Import logic handler for backup functionality
class BackupImportLogicHandler: ObservableObject {
    @Published var isImporting = false
    @Published var importResult: BackupImportResult?
    @Published var showingConfirmation = false
    @Published var previewBackupFile: PayslipBackupFile?

    private var pendingImportData: Data?

    private let backupService: BackupService
    private let onError: (String) -> Void
    private let onSuccess: () -> Void
    private var currentStrategy: ImportStrategy = .skipDuplicates

    init(backupService: BackupService, onError: @escaping (String) -> Void, onSuccess: @escaping () -> Void) {
        self.backupService = backupService
        self.onError = onError
        self.onSuccess = onSuccess
    }

    func updateStrategy(_ strategy: ImportStrategy) {
        currentStrategy = strategy
    }

    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            print("File picker returned \(urls.count) URLs")
            guard let url = urls.first else {
                print("No URLs returned from file picker")
                onError("No file was selected")
                return
            }
            print("Selected file URL: \(url)")
            prepareImportPreview(from: url)
        case .failure(let error):
            print("File picker failed with error: \(error)")
            onError("File selection failed: \(error.localizedDescription)")
        }
    }

    func confirmImport() {
        guard let data = pendingImportData else {
            onError("No backup data available to import")
            return
        }

        performImport(with: data, strategy: currentStrategy)
    }

    func cancelImport() {
        pendingImportData = nil
        previewBackupFile = nil
        showingConfirmation = false
    }

    private func prepareImportPreview(from url: URL) {
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
                print("Attempting to read from URL: \(url)")

                // Read the file data
                let data: Data = try readFileData(from: url)

                // Validate data
                guard !data.isEmpty else {
                    throw BackupError.importFailed("File contains no data")
                }

                // Decode for preview
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let backupFile = try decoder.decode(PayslipBackupFile.self, from: data)

                await MainActor.run {
                    self.pendingImportData = data
                    self.previewBackupFile = backupFile
                    self.showingConfirmation = true
                    self.isImporting = false
                }
            } catch {
                await MainActor.run {
                    let errorMsg = "Failed to read backup file: \(error.localizedDescription)"
                    print("Backup preview error: \(error)")
                    isImporting = false
                    onError(errorMsg)
                }
            }
        }
    }

    private func performImport(with data: Data, strategy: ImportStrategy) {
        isImporting = true
        showingConfirmation = false

        Task {
            do {
                print("About to import \(data.count) bytes of backup data")

                // Import the backup
                let result = try await backupService.importBackup(from: data, strategy: strategy)

                await MainActor.run {
                    importResult = result
                    isImporting = false
                    pendingImportData = nil
                    previewBackupFile = nil
                    onSuccess()
                    print("Import completed successfully: \(result.summary.successfulImports) payslips imported")
                }
            } catch {
                await MainActor.run {
                    let errorMsg = "Import failed: \(error.localizedDescription)"
                    print("Backup import error: \(error)")
                    isImporting = false
                    onError(errorMsg)
                }
            }
        }
    }

    private func readFileData(from url: URL) throws -> Data {
        do {
            // First try direct read
            let data = try Data(contentsOf: url)
            print("Successfully read \(data.count) bytes from backup file")
            return data
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
                let data = try Data(contentsOf: tempURL)
                print("Successfully read \(data.count) bytes from copied file")

                // Clean up
                try? FileManager.default.removeItem(at: tempURL)
                return data
            } catch let copyError {
                print("Copy approach also failed: \(copyError)")
                throw BackupError.importFailed("Unable to read file: \(readError.localizedDescription)")
            }
        }
    }
}

// MARK: - ImportStrategy Extension

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
