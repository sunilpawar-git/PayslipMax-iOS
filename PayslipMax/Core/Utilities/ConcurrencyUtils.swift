import Foundation

/// Executes an asynchronous operation with a specified timeout.
/// If the operation does not complete within the timeout period, it returns a `.failure` with the provided timeout error.
/// - Parameters:
///   - seconds: The timeout duration in seconds.
///   - timeoutError: The error to return if the operation times out.
///   - operation: The asynchronous operation to perform, returning a `Result<T, E>`.
/// - Returns: The result of the operation or the `timeoutError`.
func withTaskTimeout<T, E: Error>(seconds: TimeInterval, timeoutError: E, operation: @escaping () async -> Result<T, E>) async -> Result<T, E> {
    return await withTaskGroup(of: Result<T, E>.self) { group in
        // Add the actual operation
        group.addTask {
            return await operation()
        }
        
        // Add a timeout task
        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return .failure(timeoutError)
        }
        
        // Return the first completed task
        if let result = await group.next() {
            group.cancelAll() // Cancel any remaining tasks
            return result
        }
        
        // Should theoretically not be reached if timeoutError is provided correctly, but provide a fallback.
        return .failure(timeoutError) 
    }
} 