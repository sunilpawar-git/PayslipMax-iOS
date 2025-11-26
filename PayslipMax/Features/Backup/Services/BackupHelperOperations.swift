import Foundation
import SwiftData
import CryptoKit
import UIKit

/// Provides helper operations for backup service
class BackupHelperOperations: BackupHelperOperationsProtocol {

    /// Generate QR code data for sharing backup
    nonisolated func generateQRCode(for backupResult: BackupExportResult, shareType: BackupShareType) throws -> BackupQRInfo {
        let securityToken = generateSecurityToken()
        let expirationTime = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        return BackupQRInfo(
            shareType: shareType,
            location: "temp_location", // This would be set by the caller based on where they save the file
            metadata: backupResult.backupFile.metadata,
            securityToken: securityToken,
            expiresAt: expirationTime
        )
    }

    /// Convert PayslipDTOs to backup format with encryption
    func convertToBackupFormat(_ payslips: [PayslipDTO]) async throws -> [BackupPayslipItem] {
        var backupPayslips: [BackupPayslipItem] = []

        for payslip in payslips {
            // Encrypt sensitive data if not already encrypted
            var encryptedSensitiveData: Data? = nil

            if !payslip.name.isEmpty || !payslip.accountNumber.isEmpty || !payslip.panNumber.isEmpty {
                let sensitiveDataString = "\(payslip.name)|\(payslip.accountNumber)|\(payslip.panNumber)"
                let sensitiveData = sensitiveDataString.data(using: .utf8) ?? Data()

                // Use the encryption service from SecureDataManager
                // Note: We'll create a simpler encryption approach for backup
                let encryptionService = EncryptionService()
                encryptedSensitiveData = try encryptionService.encrypt(sensitiveData)
            }

            let backupPayslip = BackupPayslipItem(from: payslip, encryptedSensitiveData: encryptedSensitiveData)
            backupPayslips.append(backupPayslip)
        }

        return backupPayslips
    }

    /// Convert backup format back to PayslipDTO
    func convertFromBackupFormat(_ backupPayslip: BackupPayslipItem) async throws -> PayslipDTO {
        // Decrypt sensitive data
        var name = ""
        var accountNumber = ""
        var panNumber = ""

        if let encryptedData = backupPayslip.encryptedSensitiveData {
            do {
                // Use the encryption service to decrypt
                let encryptionService = EncryptionService()
                let decryptedData = try encryptionService.decrypt(encryptedData)
                let decryptedString = String(data: decryptedData, encoding: .utf8) ?? ""
                let components = decryptedString.split(separator: "|", maxSplits: 2)

                if components.count >= 3 {
                    name = String(components[0])
                    accountNumber = String(components[1])
                    panNumber = String(components[2])
                }
            } catch {
                // If decryption fails, leave fields empty
                print("Failed to decrypt sensitive data for payslip \(backupPayslip.id): \(error)")
            }
        }

        return PayslipDTO(
            id: backupPayslip.id,
            timestamp: backupPayslip.timestamp,
            month: backupPayslip.month,
            year: backupPayslip.year,
            credits: backupPayslip.credits,
            debits: backupPayslip.debits,
            dsop: backupPayslip.dsop,
            tax: backupPayslip.tax,
            earnings: backupPayslip.earnings,
            deductions: backupPayslip.deductions,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            isNameEncrypted: !name.isEmpty,
            isAccountNumberEncrypted: !accountNumber.isEmpty,
            isPanNumberEncrypted: !panNumber.isEmpty,
            encryptionVersion: backupPayslip.encryptionVersion,
            pdfData: backupPayslip.pdfData,  // Restore PDF data from backup
            pdfURL: nil,  // URL is device-specific, not restored
            isSample: backupPayslip.isSample,
            source: backupPayslip.source,
            status: backupPayslip.status,
            notes: backupPayslip.notes,
            numberOfPages: backupPayslip.numberOfPages,
            metadata: backupPayslip.metadata
        )
    }

    /// Generate metadata for backup
    func generateMetadata(for payslips: [BackupPayslipItem]) -> BackupMetadata {
        let totalPayslips = payslips.count

        // Calculate date range
        let dates = payslips.map { $0.timestamp }.sorted()
        let earliest = dates.first ?? Date()
        let latest = dates.last ?? Date()
        let dateRange = BackupDateRange(earliest: earliest, latest: latest)

        // Estimate file size (rough calculation)
        let estimatedSize = totalPayslips * 2048 // ~2KB per payslip

        return BackupMetadata(
            totalPayslips: totalPayslips,
            dateRange: dateRange,
            estimatedSize: estimatedSize
        )
    }

    /// Determine if a payslip should be imported based on strategy
    func shouldImportPayslip(
        _ backupPayslip: BackupPayslipItem,
        existingIds: Set<UUID>,
        strategy: ImportStrategy
    ) async throws -> Bool {
        let exists = existingIds.contains(backupPayslip.id)

        switch strategy {
        case .replaceAll:
            return true
        case .skipDuplicates:
            return !exists
        case .mergeUpdates:
            // For now, treat as skipDuplicates. Could be enhanced to compare timestamps
            return !exists
        case .askUser:
            // Not implemented in this version
            return !exists
        }
    }

    /// Calculate SHA256 checksum for data integrity
    func calculateChecksum(for data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Generate unique device identifier
    func getDeviceIdentifier() async -> String {
        // Use a combination of device model and a stored UUID
        let deviceModel = await MainActor.run {
            UIDevice.current.model
        }
        let storedUUID = UserDefaults.standard.string(forKey: "PayslipMax_DeviceUUID") ?? {
            let newUUID = UUID().uuidString
            UserDefaults.standard.set(newUUID, forKey: "PayslipMax_DeviceUUID")
            return newUUID
        }()

        return "\(deviceModel)-\(storedUUID)"
    }

    /// Get current user name (if available)
    func getCurrentUserName() async -> String? {
        // Could be enhanced to get from user settings or first payslip
        return await MainActor.run {
            UIDevice.current.name
        }
    }

    /// Generate backup filename with timestamp
    func generateBackupFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = formatter.string(from: Date())
        return "PayslipMax_Backup_\(timestamp).json"
    }

    /// Generate security token for QR codes
    nonisolated func generateSecurityToken() -> String {
        let tokenData = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        return tokenData.base64EncodedString()
    }
}
