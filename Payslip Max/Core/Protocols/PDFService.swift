import Foundation

/// A protocol that defines the requirements for a PDF service.
///
/// The PDF service provides functionality for processing and extracting
/// information from PDF files.
protocol PDFService: ServiceProtocol {
    /// Processes the PDF file at the specified URL.
    ///
    /// - Parameter url: The URL of the PDF file to process.
    /// - Returns: The processed data.
    /// - Throws: An error if processing fails.
    func process(_ url: URL) async throws -> Data
    
    /// Extracts information from the processed data.
    ///
    /// - Parameter data: The processed data.
    /// - Returns: The extracted information.
    /// - Throws: An error if extraction fails.
    func extract(_ data: Data) async throws -> Any
    
    /// Unlocks a password-protected PDF document with the provided password.
    ///
    /// - Parameters:
    ///   - data: The PDF data to unlock.
    ///   - password: The password to use for unlocking.
    /// - Returns: The unlocked PDF data.
    /// - Throws: An error if unlocking fails.
    func unlockPDF(data: Data, password: String) async throws -> Data
} 