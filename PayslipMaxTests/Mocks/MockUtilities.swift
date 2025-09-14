import Foundation

// MARK: - Notification Extensions
// Note: Notification names are defined in the main app module (PayslipEvents.swift)
// Test files should use the production notification names to ensure consistency

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
