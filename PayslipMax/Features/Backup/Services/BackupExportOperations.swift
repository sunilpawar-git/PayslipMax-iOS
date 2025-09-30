import Foundation
import SwiftData
import CryptoKit

/// Handles backup export operations
/// Updated for Swift 6 Sendable compliance using PayslipDTO
class BackupExportOperations: BackupExportOperationsProtocol {

    private let repository: SendablePayslipRepository
    private let helperOperations: BackupHelperOperationsProtocol

    init(repository: SendablePayslipRepository, helperOperations: BackupHelperOperationsProtocol) {
        self.repository = repository
        self.helperOperations = helperOperations
    }

    /// Export all payslip data to a backup file
    func exportBackup() async throws -> BackupExportResult {
        // Fetch all payslip items as DTOs (Sendable)
        let payslipDTOs = try await repository.fetchAllPayslips()

        guard !payslipDTOs.isEmpty else {
            throw BackupError.noDataToBackup
        }

        // Convert to backup format (now using DTOs)
        let backupPayslips = try await helperOperations.convertToBackupFormat(payslipDTOs)

        // Generate metadata
        let metadata = helperOperations.generateMetadata(for: backupPayslips)

        // Create backup file
        let backupFile = PayslipBackupFile(
            version: PayslipBackupFile.currentVersion,
            exportDate: Date(),
            deviceId: await helperOperations.getDeviceIdentifier(),
            encryptionVersion: PayslipBackupFile.currentEncryptionVersion,
            userName: await helperOperations.getCurrentUserName(),
            payslips: backupPayslips,
            metadata: metadata,
            checksum: "" // Will be calculated after encoding
        )

        // Encode to JSON first without checksum to calculate hash
        // Use consistent encoder settings for reproducible JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        // Ensure consistent key ordering for reproducible JSON
        if #available(iOS 13.0, *) {
            encoder.outputFormatting.insert(.sortedKeys)
        }

        // Create a temporary backup file without checksum for hash calculation
        let tempBackupFile = PayslipBackupFile(
            version: backupFile.version,
            exportDate: backupFile.exportDate,
            deviceId: backupFile.deviceId,
            encryptionVersion: backupFile.encryptionVersion,
            userName: backupFile.userName,
            payslips: backupFile.payslips,
            metadata: backupFile.metadata,
            checksum: "" // Empty checksum for calculation
        )

        let tempData = try encoder.encode(tempBackupFile)
        print("Export: Temp data size for checksum: \(tempData.count) bytes")

        // Calculate checksum on the data without checksum field
        let checksum = helperOperations.calculateChecksum(for: tempData)
        print("Export: Calculated checksum: \(checksum)")

        // Create final backup file with calculated checksum
        let finalBackupFile = PayslipBackupFile(
            version: backupFile.version,
            exportDate: backupFile.exportDate,
            deviceId: backupFile.deviceId,
            encryptionVersion: backupFile.encryptionVersion,
            userName: backupFile.userName,
            payslips: backupFile.payslips,
            metadata: backupFile.metadata,
            checksum: checksum
        )

        // Encode final file with checksum
        let fileData = try encoder.encode(finalBackupFile)
        print("Export: Final file size: \(fileData.count) bytes")

        // Generate filename
        let filename = helperOperations.generateBackupFilename()

        // Create summary
        let summary = ExportSummary(
            totalPayslips: payslipDTOs.count,
            fileSize: fileData.count,
            exportDate: Date(),
            encryptionEnabled: true
        )

        return BackupExportResult(
            backupFile: finalBackupFile,
            fileData: fileData,
            filename: filename,
            summary: summary
        )
    }
}
