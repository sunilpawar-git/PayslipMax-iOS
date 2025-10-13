import Foundation

/// A comprehensive error type for the application.
///
/// This enum provides a centralized way to handle errors throughout the app,
/// with specific error cases for different domains and user-friendly error messages.
enum AppError: Error, Identifiable, Equatable, LocalizedError {
    // MARK: - Error Cases
    
    // --- Authentication errors ---
    /// Authentication failed, typically due to incorrect credentials or user cancellation. Includes a descriptive reason.
    case authenticationFailed(String)
    /// Biometric authentication (Face ID/Touch ID) is not available or not configured on the device.
    case biometricAuthUnavailable
    /// Biometric authentication attempt failed (e.g., user failed to authenticate).
    case biometricAuthFailed
    
    // --- Network errors ---
    /// The network connection appears to be offline.
    case networkConnectionLost
    /// A network request failed with a specific HTTP status code.
    case requestFailed(Int)
    /// The response received from the server was invalid or could not be parsed.
    case invalidResponse
    /// The server returned an error. Includes a server-provided message if available.
    case serverError(String)
    /// The network request timed out before receiving a response.
    case timeoutError
    
    // --- Data errors ---
    /// Stored data appears to be corrupted or in an invalid format.
    case dataCorrupted
    /// Failed to save data for a specific entity (e.g., "PayslipItem").
    case saveFailed(String)
    /// Failed to fetch data for a specific entity (e.g., "PayslipItem").
    case fetchFailed(String)
    /// Failed to delete data for a specific entity (e.g., "PayslipItem").
    case deleteFailed(String)
    
    // --- PDF errors ---
    /// A general failure occurred during PDF processing. Includes a descriptive reason.
    case pdfProcessingFailed(String)
    /// Failed to extract data or text content from the PDF. Includes a descriptive reason.
    case pdfExtractionFailed(String)
    /// The provided PDF does not appear to be a valid or supported payslip format.
    case invalidPDFFormat
    /// Failed to extract specific data fields from the file content. Includes a descriptive reason.
    case dataExtractionFailed(String)
    /// The provided file is not a supported type (e.g., not a PDF or image). Includes a descriptive reason.
    case invalidFileType(String)
    /// The PDF is protected by a password. Includes context or reason if available.
    case passwordProtectedPDF(String)
    
    // --- Security errors ---
    /// Failed to encrypt data. Includes a descriptive reason.
    case encryptionFailed(String)
    /// Failed to decrypt data. Includes a descriptive reason.
    case decryptionFailed(String)
    
    // --- General errors ---
    /// An unknown or unexpected error occurred, wrapping the original `Error`.
    case unknown(Error)
    /// A simple error represented by a user-facing message string.
    case message(String)
    /// A generic operation failed. Includes a descriptive reason.
    case operationFailed(String)
    
    // MARK: - Identifiable Conformance
    
    /// The unique identifier for the error.
    var id: String {
        switch self {
        case .authenticationFailed(let reason):
            return "auth_failed_\(reason)"
        case .biometricAuthUnavailable:
            return "biometric_unavailable"
        case .biometricAuthFailed:
            return "biometric_failed"
        case .networkConnectionLost:
            return "network_lost"
        case .requestFailed(let statusCode):
            return "request_failed_\(statusCode)"
        case .invalidResponse:
            return "invalid_response"
        case .serverError(let message):
            return "server_error_\(message)"
        case .timeoutError:
            return "timeout"
        case .dataCorrupted:
            return "data_corrupted"
        case .saveFailed(let entity):
            return "save_failed_\(entity)"
        case .fetchFailed(let entity):
            return "fetch_failed_\(entity)"
        case .deleteFailed(let entity):
            return "delete_failed_\(entity)"
        case .pdfProcessingFailed(let reason):
            return "pdf_processing_failed_\(reason)"
        case .pdfExtractionFailed(let reason):
            return "pdf_extraction_failed_\(reason)"
        case .invalidPDFFormat:
            return "invalid_pdf_format"
        case .dataExtractionFailed(let reason):
            return "data_extraction_failed_\(reason)"
        case .invalidFileType(let reason):
            return "invalid_file_type_\(reason)"
        case .passwordProtectedPDF(let reason):
            return "password_protected_pdf_\(reason)"
        case .encryptionFailed(let reason):
            return "encryption_failed_\(reason)"
        case .decryptionFailed(let reason):
            return "decryption_failed_\(reason)"
        case .unknown(let error):
            return "unknown_\(error.localizedDescription)"
        case .message(let message):
            return "message_\(message)"
        case .operationFailed(let reason):
            return "operation_failed_\(reason)"
        }
    }
    
    // MARK: - LocalizedError Conformance
    
    /// Provides a localized description for the error (required by LocalizedError).
    var errorDescription: String? {
        return userMessage
    }
    
    // MARK: - User-Facing Error Messages
    
    /// A user-friendly error message.
    var userMessage: String {
        switch self {
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials and try again."
        case .biometricAuthUnavailable:
            return "Biometric authentication is not available on this device."
        case .biometricAuthFailed:
            return "Biometric authentication failed. Please try again or use your PIN."
        case .networkConnectionLost:
            return "Network connection lost. Please check your internet connection and try again."
        case .requestFailed:
            return "The request failed. Please try again later."
        case .invalidResponse:
            return "Received an invalid response from the server. Please try again later."
        case .serverError:
            return "A server error occurred. Our team has been notified and is working on a fix."
        case .timeoutError:
            return "The request timed out. Please check your internet connection and try again."
        case .dataCorrupted:
            return "The data appears to be corrupted. Please try again."
        case .saveFailed:
            return "Failed to save data. Please try again."
        case .fetchFailed:
            return "Failed to fetch data. Please try again."
        case .deleteFailed:
            return "Failed to delete data. Please try again."
        case .pdfProcessingFailed:
            return "Failed to process the PDF. Please ensure it's a valid payslip."
        case .pdfExtractionFailed:
            return "Failed to extract data from the PDF. Please ensure it's a valid payslip."
        case .invalidPDFFormat:
            return "The PDF format is not supported. Please ensure it's a valid payslip."
        case .dataExtractionFailed:
            return "Failed to extract data from the file. Please ensure it's a valid file."
        case .invalidFileType:
            return "The file type is not supported. Please ensure it's a valid file."
        case .passwordProtectedPDF:
            return "This PDF is password protected. Please enter the password to continue."
        case .encryptionFailed:
            return "Failed to encrypt sensitive data. Please try again."
        case .decryptionFailed:
            return "Failed to decrypt sensitive data. Please try again."
        case .unknown:
            return "An unexpected error occurred. Please try again later."
        case .message(let message):
            return message
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        }
    }
    
    /// A more detailed error message for debugging.
    var debugDescription: String {
        switch self {
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .biometricAuthUnavailable:
            return "Biometric authentication is not available on this device"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        case .networkConnectionLost:
            return "Network connection lost"
        case .requestFailed(let statusCode):
            return "Request failed with status code: \(statusCode)"
        case .invalidResponse:
            return "Received an invalid response from the server"
        case .serverError(let message):
            return "Server error: \(message)"
        case .timeoutError:
            return "Request timed out"
        case .dataCorrupted:
            return "Data corrupted"
        case .saveFailed(let entity):
            return "Failed to save \(entity)"
        case .fetchFailed(let entity):
            return "Failed to fetch \(entity)"
        case .deleteFailed(let entity):
            return "Failed to delete \(entity)"
        case .pdfProcessingFailed(let reason):
            return "PDF processing failed: \(reason)"
        case .pdfExtractionFailed(let reason):
            return "PDF extraction failed: \(reason)"
        case .invalidPDFFormat:
            return "Invalid PDF format"
        case .dataExtractionFailed(let reason):
            return "Data extraction failed: \(reason)"
        case .invalidFileType(let reason):
            return "Invalid file type: \(reason)"
        case .passwordProtectedPDF(let reason):
            return "Password protected PDF: \(reason)"
        case .encryptionFailed(let reason):
            return "Encryption failed: \(reason)"
        case .decryptionFailed(let reason):
            return "Decryption failed: \(reason)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        case .message(let message):
            return message
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        }
    }
    
    // MARK: - Error Conversion
    
    /// Converts a standard Error to an AppError.
    ///
    /// - Parameter error: The error to convert.
    /// - Returns: An AppError.
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // Convert known error types
        let nsError = error as NSError
        
        // Network errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return .networkConnectionLost
            case NSURLErrorTimedOut:
                return .timeoutError
            default:
                break
            }
        }
        
        return .unknown(error)
    }
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Error Handling Extensions

extension Result where Failure == Error {
    /// Maps any error to an AppError.
    ///
    /// - Returns: A Result with the same Success type but with AppError as the Failure type.
    func mapError() -> Result<Success, AppError> {
        mapError { AppError.from($0) }
    }
}

// MARK: - Error Logging

/// A service for logging errors.
class ErrorLogger {
    /// Logs an error.
    ///
    /// - Parameters:
    ///   - error: The error to log.
    ///   - file: The file where the error occurred.
    ///   - function: The function where the error occurred.
    ///   - line: The line where the error occurred.
    static func log(
        _ error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let appError = AppError.from(error)
        Logger.error("Error: \(appError.debugDescription)", category: "Error", file: file, function: function, line: line)
    }
} 