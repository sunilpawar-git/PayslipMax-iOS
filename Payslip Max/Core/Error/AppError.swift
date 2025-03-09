import Foundation

/// A comprehensive error type for the application.
///
/// This enum provides a centralized way to handle errors throughout the app,
/// with specific error cases for different domains and user-friendly error messages.
enum AppError: Error, Identifiable, Equatable {
    // MARK: - Error Cases
    
    // Authentication errors
    case authenticationFailed(String)
    case biometricAuthUnavailable
    case biometricAuthFailed
    
    // Network errors
    case networkConnectionLost
    case requestFailed(Int)
    case invalidResponse
    case serverError(String)
    case timeoutError
    
    // Data errors
    case dataCorrupted
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    
    // PDF errors
    case pdfProcessingFailed(String)
    case pdfExtractionFailed(String)
    case invalidPDFFormat
    
    // Security errors
    case encryptionFailed(String)
    case decryptionFailed(String)
    
    // General errors
    case unknown(Error)
    case message(String)
    
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
        case .encryptionFailed(let reason):
            return "encryption_failed_\(reason)"
        case .decryptionFailed(let reason):
            return "decryption_failed_\(reason)"
        case .unknown(let error):
            return "unknown_\(error.localizedDescription)"
        case .message(let message):
            return "message_\(message)"
        }
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
        case .encryptionFailed:
            return "Failed to encrypt sensitive data. Please try again."
        case .decryptionFailed:
            return "Failed to decrypt sensitive data. Please try again."
        case .unknown:
            return "An unexpected error occurred. Please try again later."
        case .message(let message):
            return message
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
        case .encryptionFailed(let reason):
            return "Encryption failed: \(reason)"
        case .decryptionFailed(let reason):
            return "Decryption failed: \(reason)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        case .message(let message):
            return message
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
        
        #if DEBUG
        print("🔴 ERROR: \(appError.debugDescription)")
        print("📍 Location: \(file):\(line) - \(function)")
        #else
        // In production, we would send this to a logging service
        // logToService(appError, file: file, function: function, line: line)
        #endif
    }
}

// MARK: - UI Components for Error Handling

import SwiftUI

/// A view modifier that shows an error alert.
struct ErrorAlert: ViewModifier {
    @Binding var error: AppError?
    var onDismiss: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: Binding<Bool>(
                    get: { error != nil },
                    set: { if !$0 { error = nil; onDismiss?() } }
                ),
                actions: {
                    Button("OK", role: .cancel) {
                        error = nil
                        onDismiss?()
                    }
                },
                message: {
                    if let error = error {
                        Text(error.userMessage)
                    }
                }
            )
    }
}

extension View {
    /// Adds an error alert to the view.
    ///
    /// - Parameters:
    ///   - error: A binding to the error.
    ///   - onDismiss: A closure to call when the alert is dismissed.
    /// - Returns: A view with an error alert.
    func errorAlert(error: Binding<AppError?>, onDismiss: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlert(error: error, onDismiss: onDismiss))
    }
} 