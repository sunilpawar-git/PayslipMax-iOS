import Foundation
import SwiftData
import CryptoKit

/// Handles backup validation operations
class BackupValidationOperations: BackupValidationOperationsProtocol {

    private let helperOperations: BackupHelperOperationsProtocol

    init(helperOperations: BackupHelperOperationsProtocol) {
        self.helperOperations = helperOperations
    }

    /// Validate a backup file without importing
    func validateBackup(data: Data) async throws -> PayslipBackupFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let backupFile: PayslipBackupFile
        do {
            backupFile = try decoder.decode(PayslipBackupFile.self, from: data)
        } catch {
            throw BackupError.invalidBackupFile("Failed to decode backup file: \(error.localizedDescription)")
        }

        // Validate version compatibility
        guard backupFile.version == PayslipBackupFile.currentVersion else {
            throw BackupError.incompatibleVersion(backupFile.version)
        }

        // Validate checksum by recreating the file without checksum and comparing
        // Use the same encoder settings as export to ensure consistency
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        // Ensure consistent key ordering for reproducible JSON
        if #available(iOS 13.0, *) {
            encoder.outputFormatting.insert(.sortedKeys)
        }

        // Create backup file without checksum for validation
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

        do {
            let tempData = try encoder.encode(tempBackupFile)
            let calculatedChecksum = helperOperations.calculateChecksum(for: tempData)

            print("Stored checksum: \(backupFile.checksum)")
            print("Calculated checksum: \(calculatedChecksum)")
            print("Temp data size: \(tempData.count) bytes")

            if backupFile.checksum != calculatedChecksum {
                // For debugging, let's also try without pretty printing
                let compactEncoder = JSONEncoder()
                compactEncoder.dateEncodingStrategy = .iso8601
                if #available(iOS 13.0, *) {
                    compactEncoder.outputFormatting.insert(.sortedKeys)
                }

                let compactData = try compactEncoder.encode(tempBackupFile)
                let compactChecksum = helperOperations.calculateChecksum(for: compactData)
                print("Compact checksum: \(compactChecksum)")
                print("Compact data size: \(compactData.count) bytes")

                // Try one more approach - minimal encoder
                let minimalEncoder = JSONEncoder()
                minimalEncoder.dateEncodingStrategy = .iso8601
                let minimalData = try minimalEncoder.encode(tempBackupFile)
                let minimalChecksum = helperOperations.calculateChecksum(for: minimalData)
                print("Minimal checksum: \(minimalChecksum)")
                print("Minimal data size: \(minimalData.count) bytes")

                // Checksum validation failed - backup file may be corrupted or tampered with
                print("⚠️ CHECKSUM MISMATCH - Backup file integrity check failed")
                print("Expected: \(backupFile.checksum)")
                print("Calculated: \(calculatedChecksum)")
                throw BackupError.checksumMismatch
            }
        } catch BackupError.checksumMismatch {
            throw BackupError.checksumMismatch
        } catch let encodingError {
            print("Failed to re-encode backup file for checksum validation: \(encodingError)")
            throw BackupError.invalidBackupFile("Failed to validate backup file integrity")
        }

        return backupFile
    }
}
