import Foundation
import PDFKit
@testable import PayslipMax

// MARK: - Mock Password Protected PDF Handler

/// Mock implementation of PasswordProtectedPDFHandler for testing purposes.
/// Provides configurable behavior for password-protected PDF operations.
class MockPasswordProtectedPDFHandler: PasswordProtectedPDFHandler {
    var showPasswordEntryCalled = false
    var resetPasswordStateCalled = false

    /// Initializes the mock with a mock PDF service for testing
    init() {
        let mockPDFService = MockPDFService()
        super.init(pdfService: mockPDFService)
    }

    /// Shows password entry interface for protected PDF
    override func showPasswordEntry(for data: Data) {
        showPasswordEntryCalled = true
        currentPasswordProtectedPDFData = data
        showPasswordEntryView = true
    }

    /// Resets the password state to initial values
    override func resetPasswordState() {
        resetPasswordStateCalled = true
        showPasswordEntryView = false
        currentPasswordProtectedPDFData = nil
        currentPDFPassword = nil
    }

    /// Resets all tracking flags and calls resetPasswordState
    func reset() {
        showPasswordEntryCalled = false
        resetPasswordStateCalled = false
        resetPasswordState()
    }
}
