import Foundation
import SwiftData

/// Handles backup import operations
/// Updated for Swift 6 Sendable compliance using PayslipDTO
class BackupImportOperations: BackupImportOperationsProtocol {

    private let repository: SendablePayslipRepository
    private let helperOperations: BackupHelperOperationsProtocol

    init(repository: SendablePayslipRepository, helperOperations: BackupHelperOperationsProtocol) {
        self.repository = repository
        self.helperOperations = helperOperations
    }

    /// Import payslip data from a backup file
    func importBackup(from data: Data, strategy: ImportStrategy) async throws -> BackupImportResult {
        // Validate and decode backup file (delegate to validation operations)
        let backupFile = try await BackupValidationOperations(
            helperOperations: helperOperations
        ).validateBackup(data: data)

        // Get existing payslips for conflict resolution (as DTOs)
        let existingPayslipDTOs = try await repository.fetchAllPayslips()
        let existingIds = Set(existingPayslipDTOs.map { $0.id })

        var importedPayslips: [BackupPayslipItem] = []
        var skippedPayslips: [BackupPayslipItem] = []
        var failedPayslips: [(BackupPayslipItem, Error)] = []

        // Process each payslip according to strategy
        for backupPayslip in backupFile.payslips {
            do {
                let shouldImport = try await helperOperations.shouldImportPayslip(
                    backupPayslip,
                    existingIds: existingIds,
                    strategy: strategy
                )

                if shouldImport {
                    let payslipDTO = try await helperOperations.convertFromBackupFormat(backupPayslip)
                    _ = try await repository.savePayslip(payslipDTO)
                    importedPayslips.append(backupPayslip)
                } else {
                    skippedPayslips.append(backupPayslip)
                }
            } catch {
                failedPayslips.append((backupPayslip, error))
            }
        }

        // Create summary
        let summary = ImportSummary(
            totalProcessed: backupFile.payslips.count,
            successfulImports: importedPayslips.count,
            skippedDuplicates: skippedPayslips.count,
            failedImports: failedPayslips.count,
            importDate: Date()
        )

        return BackupImportResult(
            importedPayslips: importedPayslips,
            skippedPayslips: skippedPayslips,
            failedPayslips: failedPayslips,
            summary: summary
        )
    }
}
