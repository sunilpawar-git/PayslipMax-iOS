import Foundation

/// Enum defining possible errors that can occur during payslip processing.
enum PayslipError: Error, LocalizedError {
    /// Error indicating the required encryption service was not initialized or found.
    case encryptionServiceNotConfigured
    /// Error when the provided PDF data is corrupt or cannot be read.
    case invalidPDFData
    /// General error indicating failure during PDF processing stages (e.g., text extraction).
    case unableToProcessPDF
    /// Error indicating that data passed for processing is invalid or malformed.
    case invalidData
    /// Error when the file format is recognized but invalid (e.g., incorrect structure).
    case invalidFormat
    /// Error when the file format is not supported by the application (e.g., not PDF).
    case unsupportedFormat
    /// Error when the document contains no processable content.
    case emptyDocument
    /// Error during document conversion processes (if any).
    case conversionFailed
    /// Error indicating that the processing took too long and timed out.
    case processingTimeout
    
    /// Provides a user-friendly description for each error case.
    var errorDescription: String? {
        switch self {
        case .encryptionServiceNotConfigured:
            return "Encryption service not properly configured"
        case .invalidPDFData:
            return "Invalid PDF data provided"
        case .unableToProcessPDF:
            return "Unable to process PDF file"
        case .invalidData:
            return "Invalid data provided"
        case .invalidFormat:
            return "Invalid file format"
        case .unsupportedFormat:
            return "Unsupported file format"
        case .emptyDocument:
            return "Document appears to be empty"
        case .conversionFailed:
            return "Failed to convert document"
        case .processingTimeout:
            return "Processing timeout. Please try again with a smaller document."
        }
    }
} 