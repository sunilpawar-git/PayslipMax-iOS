import Foundation

/// Protocol for password-protected PDF handling operations
protocol PDFPasswordHandlerProtocol {
    /// Checks if the provided PDF data is password protected.
    /// - Parameter data: The PDF data to check.
    /// - Returns: `true` if the PDF is password protected, `false` otherwise.
    func isPasswordProtected(_ data: Data) -> Bool

    /// Unlocks a password-protected PDF using the provided password.
    /// - Parameters:
    ///   - data: The `Data` of the password-protected PDF.
    ///   - password: The password to use for unlocking.
    /// - Returns: A `Result` containing the `Data` of the unlocked PDF on success, or `PDFProcessingError.incorrectPassword` on failure.
    func unlockPDF(_ data: Data, password: String) async -> Result<Data, PDFProcessingError>

    /// Attempts special parsing logic on password-protected PDFs.
    /// This is a placeholder for future implementation that might extract metadata or annotations
    /// that might be available even without unlocking the document.
    /// - Parameter data: The password-protected PDF data.
    /// - Returns: An optional `PayslipItem` if any data could be extracted, otherwise `nil`.
    func attemptSpecialParsingForPasswordProtectedPDF(data: Data) -> PayslipItem?
}

/// Handles password-protected PDF operations
/// Responsible for checking password protection, unlocking PDFs, and special parsing attempts
@MainActor
class PDFPasswordHandler: PDFPasswordHandlerProtocol {
    // MARK: - Properties

    /// The core PDF service used for unlocking operations.
    private let pdfService: PDFServiceProtocol

    /// Service used for validating PDF properties including password protection.
    private let validationService: PayslipValidationServiceProtocol

    // MARK: - Initialization

    /// Initializes a new PDFPasswordHandler with its required dependencies.
    /// - Parameters:
    ///   - pdfService: The core PDF service for unlocking operations.
    ///   - validationService: Service for validating PDF properties.
    init(pdfService: PDFServiceProtocol, validationService: PayslipValidationServiceProtocol) {
        self.pdfService = pdfService
        self.validationService = validationService
    }

    // MARK: - PDFPasswordHandlerProtocol Implementation

    /// Checks if the provided PDF data is password protected.
    /// This method delegates the check to the underlying `validationService`.
    /// - Parameter data: The PDF data to check.
    /// - Returns: `true` if the PDF is password protected, `false` otherwise.
    func isPasswordProtected(_ data: Data) -> Bool {
        return validationService.isPDFPasswordProtected(data)
    }

    /// Unlocks a password-protected PDF using the provided password.
    /// Delegates the unlocking operation to the underlying `pdfService`.
    /// - Parameters:
    ///   - data: The `Data` of the password-protected PDF.
    ///   - password: The password to use for unlocking.
    /// - Returns: A `Result` containing the `Data` of the unlocked PDF on success, or `PDFProcessingError.incorrectPassword` on failure.
    func unlockPDF(_ data: Data, password: String) async -> Result<Data, PDFProcessingError> {
        do {
            let unlockedData = try await pdfService.unlockPDF(data: data, password: password)
            return .success(unlockedData)
        } catch {
            print("[PDFPasswordHandler] Error unlocking PDF: \(error)")
            return .failure(.incorrectPassword)
        }
    }

    /// Attempts special parsing logic on password-protected PDFs.
    /// In a future implementation, this could attempt to extract metadata or annotations
    /// that might be available even without unlocking the document.
    /// - Parameter data: The password-protected PDF data.
    /// - Returns: An optional `PayslipItem` if any data could be extracted, otherwise `nil`.
    func attemptSpecialParsingForPasswordProtectedPDF(data: Data) -> PayslipItem? {
        // This is a placeholder for special handling of password-protected PDFs
        // In a real implementation, we would try to extract metadata or annotations

        return nil
    }
}
