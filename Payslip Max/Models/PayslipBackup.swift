import Foundation

/// Model representing a backup of payslips in the cloud
struct PayslipBackup: Codable, Identifiable {
    /// Unique identifier for the backup
    let id: UUID
    
    /// Creation date of the backup
    let creationDate: Date
    
    /// Description of the backup
    let description: String
    
    /// Size of the backup in bytes
    let sizeInBytes: Int
    
    /// Number of payslips in the backup
    let payslipCount: Int
    
    /// Initializes a new payslip backup
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - creationDate: Creation date of the backup (defaults to current date)
    ///   - description: Description of the backup
    ///   - sizeInBytes: Size of the backup in bytes
    ///   - payslipCount: Number of payslips in the backup
    init(
        id: UUID = UUID(),
        creationDate: Date = Date(),
        description: String,
        sizeInBytes: Int,
        payslipCount: Int
    ) {
        self.id = id
        self.creationDate = creationDate
        self.description = description
        self.sizeInBytes = sizeInBytes
        self.payslipCount = payslipCount
    }
} 