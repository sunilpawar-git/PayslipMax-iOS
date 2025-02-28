import Foundation

/// Errors that can occur during cloud repository operations
enum CloudRepositoryError: Error {
    /// User does not have premium access
    case premiumAccessRequired
    
    /// Network error occurred
    case networkError(Error)
    
    /// Failed to sync payslips
    case syncFailed
    
    /// Failed to create backup
    case backupCreationFailed
    
    /// Failed to fetch backups
    case fetchBackupsFailed
    
    /// Failed to restore from backup
    case restoreFailed
    
    /// Failed to delete backup
    case deleteFailed
    
    /// Backup not found
    case backupNotFound
    
    /// User description of the error
    var localizedDescription: String {
        switch self {
        case .premiumAccessRequired:
            return "Premium access is required for this feature"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .syncFailed:
            return "Failed to sync payslips with cloud"
        case .backupCreationFailed:
            return "Failed to create backup"
        case .fetchBackupsFailed:
            return "Failed to fetch backups"
        case .restoreFailed:
            return "Failed to restore from backup"
        case .deleteFailed:
            return "Failed to delete backup"
        case .backupNotFound:
            return "Backup not found"
        }
    }
} 