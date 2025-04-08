import Foundation
import PDFKit
import SwiftUI

/// A handler for password-protected PDF operations
@MainActor
class PasswordProtectedPDFHandler {
    /// The PDF service for working with PDFs
    private let pdfService: PDFServiceProtocol
    
    /// State for password-protected PDF handling
    @Published var showPasswordEntryView = false
    @Published var currentPasswordProtectedPDFData: Data?
    @Published var currentPDFPassword: String?
    
    /// Initializes a new password-protected PDF handler
    /// - Parameter pdfService: The PDF service to use
    init(pdfService: PDFServiceProtocol) {
        self.pdfService = pdfService
    }
    
    /// Checks if the specified PDF data is password protected
    /// - Parameter data: The PDF data to check
    /// - Returns: A boolean indicating whether the PDF is password protected
    func isPasswordProtected(_ data: Data) -> Bool {
        // Create a PDFDocument from the data and check if it's locked
        if let pdfDocument = PDFDocument(data: data) {
            return pdfDocument.isLocked
        }
        return false
    }
    
    /// Attempts to unlock a password-protected PDF
    /// - Parameters:
    ///   - data: The PDF data to unlock
    ///   - password: The password to use
    /// - Returns: A result containing the unlocked PDF data or an error
    func unlockPDF(_ data: Data, password: String) async -> Result<Data, Error> {
        do {
            let unlockedData = try await pdfService.unlockPDF(data: data, password: password)
            return .success(unlockedData)
        } catch {
            return .failure(error)
        }
    }
    
    /// Resets the password state
    func resetPasswordState() {
        showPasswordEntryView = false
        currentPasswordProtectedPDFData = nil
        currentPDFPassword = nil
    }
    
    /// Shows the password entry view for a password-protected PDF
    /// - Parameter data: The password-protected PDF data
    func showPasswordEntry(for data: Data) {
        currentPasswordProtectedPDFData = data
        showPasswordEntryView = true
    }
} 