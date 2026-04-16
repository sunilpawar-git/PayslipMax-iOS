import Foundation

// MARK: - Import/Export Results

/// Result of backup import operation
struct BackupImportResult {
    /// Successfully imported payslips
    let importedPayslips: [BackupPayslipItem]
    /// Payslips that were skipped due to conflicts
    let skippedPayslips: [BackupPayslipItem]
    /// Payslips that failed to import
    let failedPayslips: [(BackupPayslipItem, Error)]
    /// Import summary
    let summary: ImportSummary

    var wasSuccessful: Bool {
        return !importedPayslips.isEmpty && failedPayslips.isEmpty
    }
}

/// Summary of import operation
struct ImportSummary {
    let totalProcessed: Int
    let successfulImports: Int
    let skippedDuplicates: Int
    let failedImports: Int
    let importDate: Date

    var successRate: Double {
        guard totalProcessed > 0 else { return 0.0 }
        return Double(successfulImports) / Double(totalProcessed)
    }
}

/// Result of backup export operation
struct BackupExportResult {
    /// The generated backup file
    let backupFile: PayslipBackupFile
    /// File data ready for sharing
    let fileData: Data
    /// Suggested filename
    let filename: String
    /// Export summary
    let summary: ExportSummary
}

/// Summary of export operation
struct ExportSummary {
    let totalPayslips: Int
    let fileSize: Int
    let exportDate: Date
    let encryptionEnabled: Bool

    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
}

// MARK: - Backup Sharing Models

/// Information for sharing backup via QR code
struct BackupQRInfo: Codable {
    /// Type of sharing (file, airdrop, cloud)
    let shareType: BackupShareType
    /// URL or path to backup file
    let location: String
    /// Backup metadata for verification
    let metadata: BackupMetadata
    /// Security token for validation
    let securityToken: String
    /// Expiration date for security
    let expiresAt: Date

    /// Generate QR code data
    var qrCodeData: Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(self)
    }
}

/// Types of backup sharing methods
enum BackupShareType: String, Codable, CaseIterable {
    case file = "file"
    case airdrop = "airdrop"
    case icloud = "icloud"
    case cloud = "cloud"

    var displayName: String {
        switch self {
        case .file: return "File Share"
        case .airdrop: return "AirDrop"
        case .icloud: return "iCloud"
        case .cloud: return "Cloud Storage"
        }
    }

    var iconName: String {
        switch self {
        case .file: return "doc.fill"
        case .airdrop: return "airplay"
        case .icloud: return "icloud.fill"
        case .cloud: return "cloud.fill"
        }
    }
}

// MARK: - Error Types

/// Errors that can occur during backup operations
enum BackupError: Error, LocalizedError {
    case exportFailed(String)
    case importFailed(String)
    case encryptionFailed(String)
    case decryptionFailed(String)
    case invalidBackupFile(String)
    case incompatibleVersion(String)
    case checksumMismatch
    case noDataToBackup
    case fileNotFound
    case insufficientStorage

    var errorDescription: String? {
        switch self {
        case .exportFailed(let message):
            return "Backup export failed: \(message)"
        case .importFailed(let message):
            return "Backup import failed: \(message)"
        case .encryptionFailed(let message):
            return "Encryption failed: \(message)"
        case .decryptionFailed(let message):
            return "Decryption failed: \(message)"
        case .invalidBackupFile(let message):
            return "Invalid backup file: \(message)"
        case .incompatibleVersion(let version):
            return "Incompatible backup version: \(version)"
        case .checksumMismatch:
            return "Backup file integrity check failed"
        case .noDataToBackup:
            return "No payslip data available for backup"
        case .fileNotFound:
            return "Backup file not found"
        case .insufficientStorage:
            return "Insufficient storage space for backup"
        }
    }
}
