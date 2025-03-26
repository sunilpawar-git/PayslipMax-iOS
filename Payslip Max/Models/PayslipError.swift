import Foundation

/// Enum defining possible errors that can occur during payslip processing.
enum PayslipError: Error, LocalizedError {
    case encryptionServiceNotConfigured
    case invalidPDFData
    case unableToProcessPDF
    case invalidData
    case invalidFormat
    case unsupportedFormat
    case emptyDocument
    case conversionFailed
    case processingTimeout
    
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