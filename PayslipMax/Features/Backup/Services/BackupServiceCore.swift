import Foundation
import SwiftData
import CryptoKit
import UIKit

/// Main service for handling backup operations
@MainActor
class BackupService: ObservableObject, BackupServiceProtocol {

    // MARK: - Dependencies

    private let dataService: DataServiceProtocol
    private let secureDataManager: SecureDataManager
    private let modelContext: ModelContext

    // MARK: - Operation Components

    private let exportOperations: BackupExportOperationsProtocol
    private let importOperations: BackupImportOperationsProtocol
    private let validationOperations: BackupValidationOperationsProtocol
    private let helperOperations: BackupHelperOperationsProtocol

    // MARK: - Initialization

    init(dataService: DataServiceProtocol, secureDataManager: SecureDataManager, modelContext: ModelContext) {
        self.dataService = dataService
        self.secureDataManager = secureDataManager
        self.modelContext = modelContext

        // Initialize operation components
        self.exportOperations = BackupExportOperations(
            dataService: dataService,
            helperOperations: BackupHelperOperations()
        )
        self.importOperations = BackupImportOperations(
            dataService: dataService,
            helperOperations: BackupHelperOperations()
        )
        self.validationOperations = BackupValidationOperations(
            helperOperations: BackupHelperOperations()
        )
        self.helperOperations = BackupHelperOperations()
    }

    // MARK: - Public Interface

    /// Export all payslip data to a backup file
    func exportBackup() async throws -> BackupExportResult {
        return try await exportOperations.exportBackup()
    }

    /// Import payslip data from a backup file
    func importBackup(from data: Data, strategy: ImportStrategy) async throws -> BackupImportResult {
        return try await importOperations.importBackup(from: data, strategy: strategy)
    }

    /// Validate a backup file without importing
    func validateBackup(data: Data) async throws -> PayslipBackupFile {
        return try await validationOperations.validateBackup(data: data)
    }

    /// Generate QR code data for sharing backup
    func generateQRCode(for backupResult: BackupExportResult, shareType: BackupShareType) throws -> BackupQRInfo {
        return try helperOperations.generateQRCode(for: backupResult, shareType: shareType)
    }
}
