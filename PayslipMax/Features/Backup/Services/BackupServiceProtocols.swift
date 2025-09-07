import Foundation

/// Protocol defining backup service functionality
@MainActor
protocol BackupServiceProtocol {
    /// Export all payslip data to a backup file
    func exportBackup() async throws -> BackupExportResult

    /// Import payslip data from a backup file
    func importBackup(from data: Data, strategy: ImportStrategy) async throws -> BackupImportResult

    /// Validate a backup file without importing
    func validateBackup(data: Data) async throws -> PayslipBackupFile

    /// Generate QR code data for sharing backup
    func generateQRCode(for backupResult: BackupExportResult, shareType: BackupShareType) throws -> BackupQRInfo
}

/// Strategies for handling import conflicts
enum ImportStrategy {
    case replaceAll      // Replace all existing data
    case skipDuplicates  // Skip items that already exist
    case mergeUpdates    // Update existing items with newer data
    case askUser         // Let user decide per conflict (not implemented in this version)
}

/// Protocol for export operations
protocol BackupExportOperationsProtocol {
    func exportBackup() async throws -> BackupExportResult
}

/// Protocol for import operations
protocol BackupImportOperationsProtocol {
    func importBackup(from data: Data, strategy: ImportStrategy) async throws -> BackupImportResult
}

/// Protocol for validation operations
protocol BackupValidationOperationsProtocol {
    func validateBackup(data: Data) async throws -> PayslipBackupFile
}

/// Protocol for helper operations
protocol BackupHelperOperationsProtocol {
    func generateQRCode(for backupResult: BackupExportResult, shareType: BackupShareType) throws -> BackupQRInfo
    func convertToBackupFormat(_ payslips: [PayslipItem]) async throws -> [BackupPayslipItem]
    func convertFromBackupFormat(_ backupPayslip: BackupPayslipItem) async throws -> PayslipItem
    func generateMetadata(for payslips: [BackupPayslipItem]) -> BackupMetadata
    func shouldImportPayslip(_ backupPayslip: BackupPayslipItem, existingIds: Set<UUID>, strategy: ImportStrategy) async throws -> Bool
    func calculateChecksum(for data: Data) -> String
    func getDeviceIdentifier() async -> String
    func getCurrentUserName() async -> String?
    func generateBackupFilename() -> String
    func generateSecurityToken() -> String
}
