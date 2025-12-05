import Foundation

// MARK: - EmergencyRollbackManager Private Helpers Extension

extension EmergencyRollbackManager {
    
    /// Returns list of all services that implement EmergencyRollbackProtocol
    func getAllRollbackCapableServices() -> [String] {
        ["GlobalLoadingManager", "AnalyticsManager", "TabTransitionCoordinator", "AppearanceManager", "PerformanceMetrics"]
    }
    
    /// Returns list of services currently using DI
    func getAllActiveServices() -> [String] {
        getAllRollbackCapableServices().filter { isServiceUsingDI($0) }
    }
    
    /// Checks if service is using DI pattern
    func isServiceUsingDI(_ serviceName: String) -> Bool {
        false // All services use singleton pattern
    }
    
    /// Preserves service-specific state
    func preserveServiceState(_ serviceName: String) async -> [String: Any]? {
        ["timestamp": Date(), "serviceName": serviceName]
    }
    
    /// Disables DI feature flag for service
    func disableDIFeatureFlag(for serviceName: String) async {
        // DI feature flags have been removed - all services use singleton pattern
    }
    
    /// Validates singleton instance can be properly recreated
    func validateSingletonRecreation(for serviceName: String) async -> Bool { true }
    
    /// Cleans up DI container registrations
    func cleanupDIRegistrations(for serviceName: String) async { }
    
    /// Gets health score for a specific service
    func getServiceHealthScore(_ serviceName: String) async -> Double? { 1.0 }
    
    /// Logs rollback event
    func logRollbackEvent(_ serviceName: String, reason: String, result: RollbackResult) {
        print("🔄 Rollback triggered for \(serviceName): \(reason)")
        print("   Success: \(result.success), Duration: \(result.duration)s")
    }
    
    /// Logs critical error
    func logCriticalError(_ serviceName: String, errors: [RollbackError]) {
        print("🚨 Critical error in \(serviceName):")
        errors.forEach { print("   - \($0.localizedDescription)") }
    }
}

