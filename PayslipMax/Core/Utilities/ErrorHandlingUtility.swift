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
class ErrorHandlingUtility: ErrorHandlingUtilityProtocol {
    /// Shared instance for convenience
    static let shared = ErrorHandlingUtility()

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

}
