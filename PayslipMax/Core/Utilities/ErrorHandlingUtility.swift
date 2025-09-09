import Foundation

/// Utility class for centralized error handling
/// Part of the unified architecture for consistent error handling across the app
@MainActor
class ErrorHandlingUtility {
    /// Shared instance for convenience
    static let shared = ErrorHandlingUtility()

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
