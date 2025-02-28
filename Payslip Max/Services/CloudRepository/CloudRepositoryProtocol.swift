import Foundation
import SwiftData

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