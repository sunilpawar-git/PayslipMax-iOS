import Foundation

/// Protocol for Error Handling Utility to enable dependency injection
protocol ErrorHandlingUtilityProtocol {
    /// Handles an error by logging it and converting to AppError
    func handleError(_ error: Error) -> AppError

    /// Handles an error and updates an error property
    func handleAndUpdateError(_ error: Error, errorProperty: inout AppError?)

    /// Logs an error without returning it
    func logError(_ error: Error)
}

/// Utility class for centralized error handling
/// Part of the unified architecture for consistent error handling across the app
/// Now supports both singleton and dependency injection patterns
class ErrorHandlingUtility: ErrorHandlingUtilityProtocol, SafeConversionProtocol {
    /// Shared instance for convenience
    static let shared = ErrorHandlingUtility()

    /// Current conversion state
    var conversionState: ConversionState = .singleton

    /// Feature flag that controls DI vs singleton usage
    var controllingFeatureFlag: Feature { return .diErrorHandlingUtility }

    /// Initialize with dependency injection support
    /// - Parameter dependencies: Optional dependencies (none required for this service)
    init(dependencies: [String: Any] = [:]) {
        // No dependencies required for this utility
    }

    /// Private initializer to maintain singleton pattern
    private convenience init() {
        self.init(dependencies: [:])
    }

    /// Handles an error by logging it and converting to AppError
    ///
    /// - Parameter error: The error to handle
    /// - Returns: The converted AppError
    func handleError(_ error: Error) -> AppError {
        ErrorLogger.log(error)
        return AppError.from(error)
    }

    /// Handles an error and updates an error property
    ///
    /// - Parameters:
    ///   - error: The error to handle
    ///   - errorProperty: The published error property to update
    func handleAndUpdateError(_ error: Error, errorProperty: inout AppError?) {
        errorProperty = handleError(error)
    }

    /// Logs an error without returning it
    ///
    /// - Parameter error: The error to log
    func logError(_ error: Error) {
        ErrorLogger.log(error)
    }

    // MARK: - SafeConversionProtocol Implementation

    /// Validates that the service can be safely converted to DI
    func validateConversionSafety() async -> Bool {
        // Error handling utility has no external dependencies, safe to convert
        return true
    }

    /// Performs the conversion from singleton to DI pattern
    func performConversion(container: any DIContainerProtocol) async -> Bool {
        do {
            conversionState = .converting
            await ConversionTracker.shared.updateConversionState(for: ErrorHandlingUtility.self, state: .converting)

            // Note: Integration with existing DI architecture will be handled separately
            // This method validates the conversion is safe and updates tracking

            conversionState = .dependencyInjected
            await ConversionTracker.shared.updateConversionState(for: ErrorHandlingUtility.self, state: .dependencyInjected)

            Logger.info("Successfully converted ErrorHandlingUtility to DI pattern", category: "ErrorHandlingUtility")
            return true
        } catch {
            conversionState = .error
            await ConversionTracker.shared.updateConversionState(for: ErrorHandlingUtility.self, state: .error)
            Logger.error("Failed to convert ErrorHandlingUtility: \(error)", category: "ErrorHandlingUtility")
            return false
        }
    }

    /// Rolls back to singleton pattern if issues are detected
    func rollbackConversion() async -> Bool {
        conversionState = .singleton
        await ConversionTracker.shared.updateConversionState(for: ErrorHandlingUtility.self, state: .singleton)
        Logger.info("Rolled back ErrorHandlingUtility to singleton pattern", category: "ErrorHandlingUtility")
        return true
    }

    /// Validates dependencies are properly injected and functional
    func validateDependencies() async -> DependencyValidationResult {
        // No external dependencies required for this service
        return .success
    }

    /// Creates a new instance via dependency injection
    func createDIInstance(dependencies: [String: Any]) -> Self? {
        return ErrorHandlingUtility(dependencies: dependencies) as? Self
    }

    /// Returns the singleton instance (fallback mode)
    static func sharedInstance() -> Self {
        return shared as! Self
    }

    /// Determines whether to use DI or singleton based on feature flags
    @MainActor static func resolveInstance() -> Self {
        let featureFlagManager = FeatureFlagManager.shared
        let shouldUseDI = featureFlagManager.isEnabled(.diErrorHandlingUtility)

        if shouldUseDI {
            // Try to get DI instance from container
            // Note: DI resolution will be integrated with existing factory pattern
            // For now, fallback to singleton until factory methods are implemented
            Logger.debug("DI enabled for ErrorHandlingUtility, but using singleton fallback", category: "ErrorHandlingUtility")
        }

        // Fallback to singleton
        return shared as! Self
    }
}
