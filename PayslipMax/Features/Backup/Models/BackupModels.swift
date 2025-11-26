import Foundation

// MARK: - Backup File Models

/// Represents a complete backup file containing all user data
struct PayslipBackupFile: Codable {
    /// Version of the backup format for future compatibility
    let version: String
    /// When this backup was created
    let exportDate: Date
    /// Unique identifier for the device that created this backup
    let deviceId: String
    /// Encryption version used for sensitive data
    let encryptionVersion: Int
    /// User's display name (for identification)
    let userName: String?
    /// All payslip items in the backup
    let payslips: [BackupPayslipItem]
    /// Backup file metadata
    let metadata: BackupMetadata
    /// Checksum for data integrity verification
    let checksum: String

    /// Current backup format version
    static let currentVersion = "1.0"
    /// Current encryption version
    static let currentEncryptionVersion = 1
}

/// Simplified payslip representation for backup/restore
struct BackupPayslipItem: Codable, Identifiable {
    let id: UUID
    let timestamp: Date

    // Financial data
    let month: String
    let year: Int
    let credits: Double
    let debits: Double
    let dsop: Double
    let tax: Double
    let earnings: [String: Double]
    let deductions: [String: Double]

    // Encrypted sensitive data (name, accountNumber, panNumber combined)
    let encryptedSensitiveData: Data?
    let encryptionVersion: Int

    // Metadata
    let isSample: Bool
    let source: String
    let status: String
    let notes: String?
    let metadata: [String: String]

    // Document info (PDF data included for complete restore)
    let hasPdfData: Bool
    let numberOfPages: Int
    let pdfData: Data?  // Include PDF data for complete backup

    /// Initialize from PayslipItem
    init(from payslipItem: PayslipItem, encryptedSensitiveData: Data? = nil) {
        self.id = payslipItem.id
        self.timestamp = payslipItem.timestamp
        self.month = payslipItem.month
        self.year = payslipItem.year
        self.credits = payslipItem.credits
        self.debits = payslipItem.debits
        self.dsop = payslipItem.dsop
        self.tax = payslipItem.tax
        self.earnings = payslipItem.earnings
        self.deductions = payslipItem.deductions
        self.encryptedSensitiveData = encryptedSensitiveData ?? payslipItem.sensitiveData
        self.encryptionVersion = payslipItem.encryptionVersion
        self.isSample = payslipItem.isSample
        self.source = payslipItem.source
        self.status = payslipItem.status
        self.notes = payslipItem.notes
        self.metadata = payslipItem.metadata
        self.hasPdfData = payslipItem.pdfData != nil
        self.numberOfPages = payslipItem.numberOfPages
        self.pdfData = payslipItem.pdfData  // Include actual PDF data
    }

    /// Initialize from PayslipDTO (Sendable)
    init(from payslipDTO: PayslipDTO, encryptedSensitiveData: Data? = nil) {
        self.id = payslipDTO.id
        self.timestamp = payslipDTO.timestamp
        self.month = payslipDTO.month
        self.year = payslipDTO.year
        self.credits = payslipDTO.credits
        self.debits = payslipDTO.debits
        self.dsop = payslipDTO.dsop
        self.tax = payslipDTO.tax
        self.earnings = payslipDTO.earnings
        self.deductions = payslipDTO.deductions
        self.encryptedSensitiveData = encryptedSensitiveData
        self.encryptionVersion = payslipDTO.encryptionVersion
        self.isSample = payslipDTO.isSample
        self.source = payslipDTO.source
        self.status = payslipDTO.status
        self.notes = payslipDTO.notes
        self.metadata = payslipDTO.metadata
        self.hasPdfData = payslipDTO.pdfData != nil  // Reflect actual PDF presence
        self.numberOfPages = payslipDTO.numberOfPages
        self.pdfData = payslipDTO.pdfData  // Include PDF data for complete backup
    }
}

/// Metadata about the backup file
struct BackupMetadata: Codable {
    /// Total number of payslips in backup
    let totalPayslips: Int
    /// Date range of payslips
    let dateRange: BackupDateRange
    /// File size in bytes (approximate)
    let estimatedSize: Int
    /// App version that created this backup
    let appVersion: String
    /// Platform (iOS)
    let platform: String
    /// User preferences/settings to restore
    let userPreferences: [String: String]

    init(totalPayslips: Int, dateRange: BackupDateRange, estimatedSize: Int) {
        self.totalPayslips = totalPayslips
        self.dateRange = dateRange
        self.estimatedSize = estimatedSize
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.platform = "iOS"
        self.userPreferences = [:]
    }
}

/// Date range for payslips in backup
struct BackupDateRange: Codable {
    let earliest: Date
    let latest: Date

    var formattedRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: earliest)) - \(formatter.string(from: latest))"
    }
}

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
