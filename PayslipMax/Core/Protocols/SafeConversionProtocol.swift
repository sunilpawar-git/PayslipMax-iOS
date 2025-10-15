import Foundation

/// Protocol for safely converting singleton services to dependency injection patterns.
/// Provides standardized conversion lifecycle management with rollback capabilities.
///
/// This protocol ensures:
/// - Safe migration from singleton to DI patterns
/// - Backward compatibility during transition
/// - Emergency rollback capabilities
/// - Validation and health checks
protocol SafeConversionProtocol {

    // MARK: - Conversion State Management

    /// The current conversion state of the service
    var conversionState: ConversionState { get }

    /// Validates that the service can be safely converted to DI
    /// - Returns: true if conversion is safe, false otherwise
    func validateConversionSafety() async -> Bool

    /// Performs the conversion from singleton to DI pattern
    /// - Parameter container: The DI container to register with
    /// - Returns: true if conversion succeeded, false otherwise
    func performConversion(container: any DIContainerProtocol) async -> Bool

    /// Rolls back to singleton pattern if issues are detected
    /// - Returns: true if rollback succeeded, false otherwise
    func rollbackConversion() async -> Bool

    // MARK: - Health Monitoring

    /// Performs health check on the converted service
    /// - Returns: Health status of the service
    func performHealthCheck() async -> ServiceHealthStatus

    /// Validates dependencies are properly injected and functional
    /// - Returns: Dependency validation result
    func validateDependencies() async -> DependencyValidationResult

    // MARK: - Dual-Mode Support

    /// Creates a new instance via dependency injection
    /// - Parameter dependencies: The required dependencies
    /// - Returns: A new service instance or nil if creation fails
    func createDIInstance(dependencies: [String: Any]) -> Self?

    /// Returns the singleton instance (fallback mode)
    /// - Returns: The singleton instance
    static func sharedInstance() -> Self
}

// MARK: - Supporting Types

/// Represents the current state of a service's DI conversion
enum ConversionState: String, CaseIterable {
    /// Service is using singleton pattern
    case singleton = "singleton"

    /// Service is in the process of being converted
    case converting = "converting"

    /// Service has been converted to DI pattern
    case dependencyInjected = "dependency_injected"

    /// Service is in rollback process
    case rollingBack = "rolling_back"

    /// Service conversion failed and is in error state
    case error = "error"
}

/// Health status for converted services
enum ServiceHealthStatus: String, CaseIterable {
    /// Service is healthy and functioning properly
    case healthy = "healthy"

    /// Service has minor issues but is functional
    case degraded = "degraded"

    /// Service has critical issues
    case unhealthy = "unhealthy"

    /// Health check failed to complete
    case unknown = "unknown"
}

/// Result of dependency validation
struct DependencyValidationResult {
    /// Whether all dependencies are properly injected
    let isValid: Bool

    /// List of missing dependencies
    let missingDependencies: [String]

    /// List of invalid dependencies
    let invalidDependencies: [String]

    /// Additional validation messages
    let messages: [String]

    /// Creates a successful validation result
    static var success: DependencyValidationResult {
        return DependencyValidationResult(
            isValid: true,
            missingDependencies: [],
            invalidDependencies: [],
            messages: ["All dependencies validated successfully"]
        )
    }

    /// Creates a failed validation result
    /// - Parameters:
    ///   - missing: Missing dependencies
    ///   - invalid: Invalid dependencies
    ///   - messages: Additional error messages
    /// - Returns: Failed validation result
    static func failure(
        missing: [String] = [],
        invalid: [String] = [],
        messages: [String] = []
    ) -> DependencyValidationResult {
        return DependencyValidationResult(
            isValid: false,
            missingDependencies: missing,
            invalidDependencies: invalid,
            messages: messages
        )
    }
}

// MARK: - Default Implementation

extension SafeConversionProtocol {

    /// Default implementation for health check
    func performHealthCheck() async -> ServiceHealthStatus {
        // Basic health check - can be overridden by conforming types
        let dependencyResult = await validateDependencies()
        return dependencyResult.isValid ? .healthy : .degraded
    }

    /// Default implementation for conversion safety validation
    func validateConversionSafety() async -> Bool {
        // Basic safety checks - can be overridden by conforming types
        let healthStatus = await performHealthCheck()
        return healthStatus == .healthy || healthStatus == .degraded
    }
}

// MARK: - Conversion Tracking

/// Tracks conversion progress and status for all services
@MainActor
class ConversionTracker {

    /// Shared instance for tracking conversions
    static let shared = ConversionTracker()

    /// Dictionary tracking conversion states by service type
    private var conversionStates: [String: ConversionState] = [:]

    /// Dictionary tracking health status by service type
    private var healthStatuses: [String: ServiceHealthStatus] = [:]

    private init() {}

    /// Updates the conversion state for a service
    /// - Parameters:
    ///   - serviceType: The type of service
    ///   - state: The new conversion state
    func updateConversionState<T>(for serviceType: T.Type, state: ConversionState) {
        let key = String(describing: serviceType)
        conversionStates[key] = state
    }

    /// Gets the conversion state for a service
    /// - Parameter serviceType: The type of service
    /// - Returns: The current conversion state
    func getConversionState<T>(for serviceType: T.Type) -> ConversionState {
        let key = String(describing: serviceType)
        return conversionStates[key] ?? .singleton
    }

    /// Updates the health status for a service
    /// - Parameters:
    ///   - serviceType: The type of service
    ///   - status: The new health status
    func updateHealthStatus<T>(for serviceType: T.Type, status: ServiceHealthStatus) {
        let key = String(describing: serviceType)
        healthStatuses[key] = status
    }

    /// Gets the health status for a service
    /// - Parameter serviceType: The type of service
    /// - Returns: The current health status
    func getHealthStatus<T>(for serviceType: T.Type) -> ServiceHealthStatus {
        let key = String(describing: serviceType)
        return healthStatuses[key] ?? .unknown
    }

    /// Gets overall conversion progress
    /// - Returns: Tuple of (converted count, total count, percentage)
    func getOverallProgress() -> (converted: Int, total: Int, percentage: Double) {
        let converted = conversionStates.values.filter { $0 == .dependencyInjected }.count
        let total = conversionStates.count
        let percentage = total > 0 ? Double(converted) / Double(total) * 100.0 : 0.0
        return (converted, total, percentage)
    }

    /// Gets services in error state
    /// - Returns: Array of service names in error state
    func getServicesInErrorState() -> [String] {
        return conversionStates.compactMap { key, state in
            state == .error ? key : nil
        }
    }
}
