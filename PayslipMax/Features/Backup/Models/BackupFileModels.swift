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
    let pdfData: Data?

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
        self.pdfData = payslipItem.pdfData
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
        self.hasPdfData = payslipDTO.pdfData != nil
        self.numberOfPages = payslipDTO.numberOfPages
        self.pdfData = payslipDTO.pdfData
    }
}

// MARK: - Backup Metadata

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
