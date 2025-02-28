import Foundation
import SwiftData

/// Model representing a backup
struct PayslipBackup: Codable {
    let id: UUID
    let createdAt: Date
    let payslipCount: Int
    let size: Int64
    let description: String?
    
    init(id: UUID = UUID(), createdAt: Date = Date(), payslipCount: Int, size: Int64, description: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.payslipCount = payslipCount
        self.size = size
        self.description = description
    }
}

/// Enum representing possible cloud repository errors
enum CloudRepositoryError: Error {
    case notAuthenticated
    case notPremiumUser
    case syncFailed(Error)
    case backupFailed(Error)
    case restoreFailed(Error)
    case networkError(Error)
    case notFound
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .notPremiumUser:
            return "This feature requires a premium subscription"
        case .syncFailed(let error):
            return "Failed to sync data: \(error.localizedDescription)"
        case .backupFailed(let error):
            return "Failed to create backup: \(error.localizedDescription)"
        case .restoreFailed(let error):
            return "Failed to restore from backup: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .notFound:
            return "The requested resource was not found"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

/// Protocol defining cloud repository operations
protocol CloudRepositoryProtocol {
    /// Syncs local payslips with the cloud
    /// - Parameter payslips: The payslips to sync
    /// - Returns: The synced payslips
    func syncPayslips(_ payslips: [PayslipItem]) async throws -> [PayslipItem]
    
    /// Creates a backup of payslips
    /// - Parameters:
    ///   - payslips: The payslips to backup
    ///   - description: Optional description for the backup
    /// - Returns: The created backup
    func createBackup(of payslips: [PayslipItem], description: String?) async throws -> PayslipBackup
    
    /// Fetches available backups
    /// - Returns: Array of available backups
    func fetchBackups() async throws -> [PayslipBackup]
    
    /// Restores payslips from a backup
    /// - Parameter backupId: The ID of the backup to restore from
    /// - Returns: The restored payslips
    func restoreFromBackup(id backupId: UUID) async throws -> [PayslipItem]
    
    /// Deletes a backup
    /// - Parameter backupId: The ID of the backup to delete
    func deleteBackup(id backupId: UUID) async throws
    
    /// Checks if the user has premium access
    /// - Returns: Boolean indicating if the user has premium access
    func hasPremiumAccess() async -> Bool
} 