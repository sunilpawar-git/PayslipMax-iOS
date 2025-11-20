import Foundation
import SwiftData
import PDFKit
import Vision
import CoreGraphics

/// Errors that can occur during PDF processing.
public enum PDFError: Error, LocalizedError {
    case notInitialized
    case fileNotFound
    case fileReadError(Error)
    case emptyFile
    case invalidPDFFormat
    case invalidPDF
    case passwordProtected
    case emptyPDF
    case processingFailed(Error)
    case encryptionFailed(Error)
    case decryptionFailed(Error)
    case noDataExtracted
    case extractionFailed(Error)
    case invalidFormat
    case dataExtractionFailed
    case invalidOperation(message: String)
    case invalidPassword

    /// A user-friendly description of the error.
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "PDF service not initialized"
        case .fileNotFound:
            return "The PDF file could not be found"
        case .fileReadError(let error):
            return "Error reading PDF file: \(error.localizedDescription)"
        case .emptyFile:
            return "The PDF file is empty"
        case .invalidPDFFormat:
            return "The file is not a valid PDF"
        case .invalidPDF:
            return "The PDF document is invalid or corrupted"
        case .passwordProtected:
            return "The PDF document is password protected"
        case .emptyPDF:
            return "The PDF document has no pages"
        case .processingFailed(let error):
            return "PDF processing failed: \(error.localizedDescription)"
        case .encryptionFailed(let error):
            return "PDF encryption failed: \(error.localizedDescription)"
        case .decryptionFailed(let error):
            return "PDF decryption failed: \(error.localizedDescription)"
        case .noDataExtracted:
            return "No payslip data could be extracted from the PDF"
        case .extractionFailed(let error):
            return "PDF data extraction failed: \(error.localizedDescription)"
        case .invalidFormat:
            return "Invalid PDF format"
        case .dataExtractionFailed:
            return "Failed to extract data from the PDF"
        case .invalidOperation(let message):
            return message
        case .invalidPassword:
            return "Invalid password provided"
        }
    }
}

/// Provides implementation for core PDF handling operations like processing, text extraction, and unlocking.
/// Requires a `SecurityServiceProtocol` dependency and utilizes a `PDFExtractorProtocol` for extraction tasks.
final class PDFServiceImpl: PDFServiceProtocol {
    // MARK: - Properties
    /// The security service used for potential encryption/decryption needs (though not directly used in current methods).
    private let securityService: SecurityServiceProtocol
    init(securityService: SecurityServiceProtocol) {
        self.securityService = securityService
    }

    /// Flag indicating if the service (including the security service dependency) is initialized.
    var isInitialized: Bool = false

    /// Initializes the service.
    ///
    /// This method initializes the security service.
    ///
    /// - Throws: An error if initialization fails.
    func initialize() async throws {
        try await securityService.initialize()
        isInitialized = true
    }

    // MARK: - PDFServiceProtocol

    /// Processes a PDF file at the specified URL.
    ///
    /// This method loads the PDF, converts it to data, and encrypts it.
    ///
    /// - Parameter url: The URL of the PDF file to process.
    /// - Returns: The encrypted PDF data.
    /// - Throws: An error if processing fails.
    func process(_ url: URL) async throws -> Data {
        guard isInitialized else {
            throw PDFError.notInitialized
        }

        do {
            print("PDFServiceImpl: Processing file at \(url.absoluteString)")

            // Check if file exists
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw PDFError.fileNotFound
            }

            // Load and return the PDF data
            let pdfData = try Data(contentsOf: url)
            return pdfData
        } catch {
            throw PDFError.processingFailed(error)
        }
    }

    /// Extracts text from a PDF.
    ///
    /// - Parameter data: The PDF data to extract text from.
    /// - Returns: A dictionary mapping page numbers to extracted text.
    func extract(_ data: Data) -> [String: String] {
        print("PDFServiceImpl: Extracting text from PDF")

        // Create a PDF document from the data
        guard let pdfDocument = PDFDocument(data: data) else {
            print("PDFServiceImpl: Could not create PDF document from data")
            return [:]
        }

        var result: [String: String] = [:]

        // Extract text from each page
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            let pageText = page.string ?? ""
            result["page_\(i+1)"] = pageText
        }

        return result
    }

    /// Unlocks a password-protected PDF document.
    ///
    /// - Parameters:
    ///   - data: The encrypted PDF data.
    ///   - password: The password to unlock the PDF.
    /// - Returns: The decrypted PDF data.
    /// - Throws: An error if decryption fails.
    func unlockPDF(data: Data, password: String) async throws -> Data {
        guard !password.isEmpty else {
            throw PDFError.passwordProtected
        }

        // Check if this is a PDF file
        guard let pdfDocument = PDFDocument(data: data) else {
            throw PDFError.invalidFormat
        }

        // If the document is not locked, return the original data
        if !pdfDocument.isLocked {
            return data
        }

        // Try to unlock with the provided password
        if pdfDocument.unlock(withPassword: password) {
            // Successfully unlocked the PDF
            if let unlockedData = pdfDocument.dataRepresentation() {
                return unlockedData
            } else {
                throw PDFError.dataExtractionFailed
            }
        } else {
            throw PDFError.passwordProtected
        }
    }
}

// MARK: - Extensions

extension UInt32 {
    /// Convert UInt32 to Data (4 bytes)
    var data: Data {
        var value = self
        return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
    }
}
