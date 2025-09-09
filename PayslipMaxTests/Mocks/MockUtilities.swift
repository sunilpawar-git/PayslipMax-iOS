import Foundation

// MARK: - Notification Extensions

/// Test notification names for payslip operations.
/// Extends Notification.Name with test-specific notification types.
extension Notification.Name {
    /// Notification posted when a payslip is deleted
    static let payslipDeleted = Notification.Name("payslipDeleted")

    /// Notification posted when a payslip is updated
    static let payslipUpdated = Notification.Name("payslipUpdated")

    /// Notification posted when payslips need to refresh
    static let payslipsRefresh = Notification.Name("payslipsRefresh")

    /// Notification posted when payslips need forced refresh
    static let payslipsForcedRefresh = Notification.Name("payslipsForcedRefresh")
}

// MARK: - Mock Global Loading Manager

/// Mock implementation of GlobalLoadingManager for testing purposes.
/// Provides configurable behavior for loading operations.
class GlobalLoadingManager {
    /// Shared instance for singleton pattern
    static let shared = GlobalLoadingManager()

    /// Private initializer to enforce singleton pattern
    private init() {}

    /// Starts a loading operation with the given operation ID and message
    func startLoading(operationId: String, message: String) {
        // Mock implementation - no actual loading behavior
    }

    /// Stops the loading operation with the given operation ID
    func stopLoading(operationId: String) {
        // Mock implementation - no actual loading behavior
    }
}
