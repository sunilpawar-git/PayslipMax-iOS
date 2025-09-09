import Foundation
@testable import PayslipMax

// MARK: - Mock Error Handler

/// Mock implementation of ErrorHandler for testing purposes.
/// Provides configurable behavior for error handling operations.
class MockErrorHandler: ErrorHandler {
    var handleErrorCalled = false
    var handlePDFErrorCalled = false
    var clearErrorCalled = false

    /// Handles general errors and tracks the call
    override func handleError(_ error: Error) {
        handleErrorCalled = true
        super.handleError(error)
    }

    /// Handles PDF-specific errors and tracks the call
    override func handlePDFError(_ error: Error) {
        handlePDFErrorCalled = true
        super.handlePDFError(error)
    }

    /// Clears the current error state and tracks the call
    override func clearError() {
        clearErrorCalled = true
        super.clearError()
    }

    /// Resets all tracking flags and clears errors
    func reset() {
        handleErrorCalled = false
        handlePDFErrorCalled = false
        clearErrorCalled = false
        clearError()
    }
}
