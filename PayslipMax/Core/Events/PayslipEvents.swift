import Foundation

/// Notification names for payslip-related events
extension Notification.Name {
    /// Posted when a payslip is deleted
    static let payslipDeleted = Notification.Name("PayslipDeleted")
    
    /// Posted when a payslip is added or updated
    static let payslipUpdated = Notification.Name("PayslipUpdated")
    
    /// Posted when all payslips should be refreshed
    static let payslipsRefresh = Notification.Name("PayslipsRefresh")
    
    /// Posted when all payslips must be forcefully reloaded from the database
    static let payslipsForcedRefresh = Notification.Name("PayslipsForcedRefresh")
}

/// Helper functions for posting payslip notifications
@MainActor
class PayslipEvents {
    /// Posts a notification that a payslip was deleted
    /// - Parameter id: The ID of the deleted payslip
    static func notifyPayslipDeleted(id: UUID) {
        NotificationCenter.default.post(
            name: .payslipDeleted,
            object: nil,
            userInfo: ["payslipId": id]
        )
        
        // Also post a forced refresh notification to ensure database consistency
        notifyForcedRefreshRequired()
    }
    
    /// Posts a notification that a payslip was updated
    /// - Parameter id: The ID of the updated payslip
    static func notifyPayslipUpdated(id: UUID) {
        NotificationCenter.default.post(
            name: .payslipUpdated,
            object: nil,
            userInfo: ["payslipId": id]
        )
        
        // Also post a refresh notification
        notifyRefreshRequired()
    }
    
    /// Posts a notification that all payslips should be refreshed
    static func notifyRefreshRequired() {
        NotificationCenter.default.post(
            name: .payslipsRefresh,
            object: nil
        )
    }
    
    /// Posts a notification that all payslips must be forcefully reloaded from the database
    /// This is more aggressive than the standard refresh and should be used for critical data changes
    static func notifyForcedRefreshRequired() {
        // First send a standard refresh
        notifyRefreshRequired()
        
        // Then send the forced refresh notification
        NotificationCenter.default.post(
            name: .payslipsForcedRefresh,
            object: nil
        )
    }
} 