import Foundation
import PDFKit

/// A comprehensive protocol for handling all PDF processing operations related to payslips
@MainActor protocol PDFProcessingServiceProtocol: ServiceProtocol {
    // MARK: - Processing Methods
    
    /// Processes a PDF file from a URL and returns the processed data
    /// - Parameter url: The URL of the PDF file to process
    /// - Returns: A result with either the processed data or an error
    func processPDF(from url: URL) async -> Result<Data, PDFProcessingError>
    
    /// Processes PDF data directly
    /// - Parameter data: The PDF data to process
    /// - Returns: A result with either the extracted payslip or an error
    func processPDFData(_ data: Data) async -> Result<PayslipItem, PDFProcessingError>
    
    /// Checks if a PDF is password protected
    /// - Parameter data: The PDF data to check
    /// - Returns: True if the PDF is password protected, false otherwise
    func isPasswordProtected(_ data: Data) -> Bool
    
    /// Unlocks a password-protected PDF
    /// - Parameters:
    ///   - data: The PDF data to unlock
    ///   - password: The password to use for unlocking
    /// - Returns: A result with either the unlocked data or an error
    func unlockPDF(_ data: Data, password: String) async -> Result<Data, PDFProcessingError>
    
    /// Processes a scanned image as a payslip
    /// - Parameter image: The scanned image
    /// - Returns: A result with either the extracted payslip or an error
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError>
    
    // MARK: - Format Detection and Validation
    
    /// Detects the format of a payslip PDF
    /// - Parameter data: The PDF data to check
    /// - Returns: The detected payslip format
    func detectPayslipFormat(_ data: Data) -> PayslipFormat
    
    /// Validates that a PDF contains valid payslip content
    /// - Parameter data: The PDF data to validate
    /// - Returns: A validation result
    func validatePayslipContent(_ data: Data) -> PayslipContentValidationResult
}

/// Represents the format of a payslip
enum PayslipFormat {
    case military
    case pcda
    case standard
    case corporate
    case psu
    case unknown
}

/// Errors that can occur during PDF processing
enum PDFProcessingError: Error, LocalizedError, Equatable, Sendable {
    case fileAccessError(String)
    case passwordProtected
    case incorrectPassword
    case parsingFailed(String)
    case extractionFailed(String)
    case invalidFormat
    case unsupportedFormat
    case emptyDocument
    case conversionFailed
    case processingTimeout
    case unableToProcessPDF
    case invalidPDFData
    case invalidData
    case invalidPDFStructure
    case textExtractionFailed
    case notAPayslip
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .fileAccessError(let message):
            return "File access error: \(message)"
        case .passwordProtected:
            return "The PDF is password protected. Please enter the password."
        case .incorrectPassword:
            return "The password provided is incorrect."
        case .parsingFailed(let message):
            return "Failed to parse payslip: \(message)"
        case .extractionFailed(let message):
            return "Failed to extract data: \(message)"
        case .invalidFormat:
            return "The file is not in a valid payslip format."
        case .unsupportedFormat:
            return "This payslip format is not currently supported."
        case .emptyDocument:
            return "The document appears to be empty."
        case .conversionFailed:
            return "Failed to convert the document."
        case .processingTimeout:
            return "Processing timeout. Please try again with a smaller document."
        case .unableToProcessPDF:
            return "Unable to process the PDF file."
        case .invalidPDFData:
            return "The PDF data is invalid or corrupted."
        case .invalidData:
            return "The data is invalid or in an unexpected format."
        case .invalidPDFStructure:
            return "The file does not appear to be a valid PDF."
        case .textExtractionFailed:
            return "Failed to extract text from the PDF."
        case .notAPayslip:
            return "The PDF does not appear to be a payslip."
        case .processingFailed:
            return "Failed to process the payslip data."
        }
    }
    
    // Implement Equatable
    static func == (lhs: PDFProcessingError, rhs: PDFProcessingError) -> Bool {
        switch (lhs, rhs) {
        case (.fileAccessError(let lhsMessage), .fileAccessError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.passwordProtected, .passwordProtected):
            return true
        case (.incorrectPassword, .incorrectPassword):
            return true
        case (.parsingFailed(let lhsMessage), .parsingFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.extractionFailed(let lhsMessage), .extractionFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.invalidFormat, .invalidFormat):
            return true
        case (.unsupportedFormat, .unsupportedFormat):
            return true
        case (.emptyDocument, .emptyDocument):
            return true
        case (.conversionFailed, .conversionFailed):
            return true
        case (.processingTimeout, .processingTimeout):
            return true
        case (.unableToProcessPDF, .unableToProcessPDF):
            return true
        case (.invalidPDFData, .invalidPDFData):
            return true
        case (.invalidData, .invalidData):
            return true
        case (.invalidPDFStructure, .invalidPDFStructure):
            return true
        case (.textExtractionFailed, .textExtractionFailed):
            return true
        case (.notAPayslip, .notAPayslip):
            return true
        case (.processingFailed, .processingFailed):
            return true
        default:
            return false
        }
    }
} 