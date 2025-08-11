import SwiftUI
import UniformTypeIdentifiers

/// Import logic handler for backup functionality  
class BackupImportLogicHandler: ObservableObject {
    @Published var isImporting = false
    @Published var importResult: BackupImportResult?
    
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
             importFromFile(url, strategy: currentStrategy)
        case .failure(let error):
            print("File picker failed with error: \(error)")
            onError("File selection failed: \(error.localizedDescription)")
        }
    }
    
    func importFromFile(_ url: URL, strategy: ImportStrategy) {
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
                let data: Data = try readFileData(from: url)
                
                // Validate data
                guard data.count > 0 else {
                    throw BackupError.importFailed("File contains no data")
                }
                
                print("About to import \(data.count) bytes of backup data")
                
                // Import the backup
                let result = try await backupService.importBackup(from: data, strategy: strategy)
                
                await MainActor.run {
                    importResult = result
                    isImporting = false
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
    
    /// Internal helper to import directly from Data (used for UI testing hooks)
    func importFromData(_ data: Data, strategy: ImportStrategy) {
        isImporting = true
        Task {
            do {
                let result = try await backupService.importBackup(from: data, strategy: strategy)
                await MainActor.run {
                    importResult = result
                    isImporting = false
                    onSuccess()
                    print("Import from data completed successfully: \(result.summary.successfulImports) payslips imported")
                }
            } catch {
                await MainActor.run {
                    let errorMsg = "Import failed: \(error.localizedDescription)"
                    print("Backup import (data) error: \(error)")
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