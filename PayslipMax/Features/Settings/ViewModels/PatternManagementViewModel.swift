import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

/// View model for pattern management
@MainActor
class PatternManagementViewModel: ObservableObject {
    
    // MARK: - Properties
    
    // Data
    @Published var patterns: [PatternDefinition] = []
    @Published var isLoading = false
    
    // Error handling
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Import/Export
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var exportedPatterns: PatternsDocument?
    @Published var showExportSuccess = false
    @Published var exportSuccessMessage = ""
    
    // Confirmation dialogs
    @Published var showResetConfirmation = false
    
    // Services
    private let patternRepository: PatternRepositoryProtocol
    
    // MARK: - Initialization
    
    init() {
        // Resolve repository from unified registry
        self.patternRepository = ServiceRegistry.shared.resolve(PatternRepositoryProtocol.self)!
    }
    
    // MARK: - Data Methods
    
    /// Load all patterns
    @MainActor
    func loadPatterns() async {
        isLoading = true
        patterns = await patternRepository.getAllPatterns()
        isLoading = false
    }
    
    /// Delete a pattern
    func deletePattern(_ pattern: PatternDefinition) {
        guard !pattern.isCore else { return }
        
        Task {
            do {
                try await patternRepository.deletePattern(withID: pattern.id)
                Task { @MainActor in await self.loadPatterns() }
            } catch {
                Task { @MainActor in self.handleError(error) }
            }
        }
    }
    
    /// Save a new pattern or update an existing one
    func savePattern(_ pattern: PatternDefinition) {
        Task {
            do {
                try await patternRepository.savePattern(pattern)
                Task { @MainActor in await self.loadPatterns() }
            } catch {
                Task { @MainActor in self.handleError(error) }
            }
        }
    }
    
    /// Reset to default patterns
    func resetToDefaultPatterns() {
        Task {
            do {
                try await patternRepository.resetToDefaults()
                Task { @MainActor in await self.loadPatterns() }
            } catch {
                Task { @MainActor in self.handleError(error) }
            }
        }
    }
    
    // MARK: - Import/Export Methods
    
    /// Export patterns to a file
    func exportPatterns() {
        Task {
            do {
                let patternsData = try await patternRepository.exportPatternsToJSON()
                Task { @MainActor in self.applyExportState(with: patternsData) }
            } catch {
                Task { @MainActor in self.handleError(error) }
            }
        }
    }
    
    /// Import patterns from a file
    func importPatterns() {
        isImporting = true
    }
    
    /// Handle the result of the file import
    @MainActor
    func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedFileURL = urls.first else { return }
            
            let didStartAccessing = selectedFileURL.startAccessingSecurityScopedResource()
            defer { 
                if didStartAccessing {
                    selectedFileURL.stopAccessingSecurityScopedResource() 
                }
            }
            
            do {
                let jsonData = try Data(contentsOf: selectedFileURL)
                
                Task {
                    do {
                        let importedCount = try await patternRepository.importPatternsFromJSON(jsonData)
                        print("Successfully imported \(importedCount) patterns")
                        Task { @MainActor in await self.loadPatterns() }
                    } catch {
                        Task { @MainActor in self.handleError(error) }
                    }
                }
            } catch {
                handleError(error)
            }
            
        case .failure(let error):
            handleError(error)
        }
    }
    
    // MARK: - Error Handling
    
    /// Handle errors
    @MainActor
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }

    // MARK: - Private Helpers
    @MainActor
    private func applyExportState(with data: Data) {
        exportedPatterns = PatternsDocument(data: data)
        isExporting = true
    }
}

/// Document type for exporting patterns
struct PatternsDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.json]
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
} 