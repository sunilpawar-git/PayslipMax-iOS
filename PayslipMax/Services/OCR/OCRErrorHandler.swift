import Foundation

/// Service for handling OCR-related errors and providing user-friendly messages
public class OCRErrorHandler {
    
    // MARK: - Shared Instance
    
    public static let shared = OCRErrorHandler()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Convert technical OCR errors into user-friendly messages
    /// - Parameter error: The technical error to convert
    /// - Returns: A user-friendly error description
    public func getUserFriendlyMessage(for error: Error) -> String {
        switch error {
        case let visionError as VisionTextExtractionError:
            return getUserFriendlyMessage(for: visionError)
        default:
            return getGenericErrorMessage(for: error)
        }
    }
    
    /// Get a user-friendly message for Vision extraction errors
    /// - Parameter error: The Vision extraction error
    /// - Returns: A user-friendly error description
    public func getUserFriendlyMessage(for error: VisionTextExtractionError) -> String {
        switch error {
        case .imageConversionFailed:
            return "Unable to process the payslip image. Please try uploading a different PDF or image file."
            
        case .visionRequestFailed(_):
            return "Text recognition encountered an issue. Please try again or contact support if the problem persists."
            
        case .noTextDetected:
            return "No text could be detected in this payslip. Please ensure the document is clear and readable, then try again."
            
        case .pdfRenderingFailed:
            return "Unable to process the PDF file. Please check that the file is not corrupted and try again."
        }
    }
    
    /// Get recovery suggestions for common OCR errors
    /// - Parameter error: The error to provide suggestions for
    /// - Returns: An array of suggested recovery actions
    public func getRecoverySuggestions(for error: Error) -> [String] {
        switch error {
        case let visionError as VisionTextExtractionError:
            return getRecoverySuggestions(for: visionError)
        default:
            return getGenericRecoverySuggestions()
        }
    }
    
    /// Get recovery suggestions for Vision extraction errors
    /// - Parameter error: The Vision extraction error
    /// - Returns: An array of suggested recovery actions
    public func getRecoverySuggestions(for error: VisionTextExtractionError) -> [String] {
        switch error {
        case .imageConversionFailed:
            return [
                "Try uploading a different PDF file",
                "Ensure the PDF is not password-protected",
                "Check that the file is not corrupted"
            ]
            
        case .visionRequestFailed(_):
            return [
                "Check your internet connection",
                "Restart the app and try again",
                "Contact support if the issue persists"
            ]
            
        case .noTextDetected:
            return [
                "Ensure the payslip image is clear and not blurry",
                "Check that the document is properly oriented",
                "Try increasing the brightness or contrast",
                "Ensure the text is large enough to be readable"
            ]
            
        case .pdfRenderingFailed:
            return [
                "Try opening the PDF in another app first",
                "Re-download or re-export the PDF",
                "Contact the payslip provider for a new copy"
            ]
        }
    }
    
    /// Determine if an error is recoverable by the user
    /// - Parameter error: The error to check
    /// - Returns: True if the user can potentially recover from this error
    public func isRecoverable(_ error: Error) -> Bool {
        switch error {
        case let visionError as VisionTextExtractionError:
            return isRecoverable(visionError)
        default:
            return true  // Most errors are potentially recoverable
        }
    }
    
    /// Determine if a Vision extraction error is recoverable
    /// - Parameter error: The Vision extraction error
    /// - Returns: True if the user can potentially recover from this error
    public func isRecoverable(_ error: VisionTextExtractionError) -> Bool {
        switch error {
        case .imageConversionFailed, .noTextDetected, .pdfRenderingFailed:
            return true
        case .visionRequestFailed(_):
            return true  // Often temporary issues
        }
    }
    
    /// Get the severity level of an error
    /// - Parameter error: The error to assess
    /// - Returns: The severity level
    public func getSeverity(of error: Error) -> ErrorSeverity {
        switch error {
        case let visionError as VisionTextExtractionError:
            return getSeverity(of: visionError)
        default:
            return .medium
        }
    }
    
    /// Get the severity level of a Vision extraction error
    /// - Parameter error: The Vision extraction error
    /// - Returns: The severity level
    public func getSeverity(of error: VisionTextExtractionError) -> ErrorSeverity {
        switch error {
        case .noTextDetected, .imageConversionFailed:
            return .high  // User action required
        case .pdfRenderingFailed:
            return .high  // File issue
        case .visionRequestFailed(_):
            return .medium  // Often temporary
        }
    }
    
    // MARK: - Private Methods
    
    /// Get a generic user-friendly message for unknown errors
    private func getGenericErrorMessage(for error: Error) -> String {
        return "An unexpected issue occurred while processing your payslip. Please try again or contact support if the problem continues."
    }
    
    /// Get generic recovery suggestions
    private func getGenericRecoverySuggestions() -> [String] {
        return [
            "Try again in a few moments",
            "Restart the app",
            "Contact support if the issue persists"
        ]
    }
}

// MARK: - Supporting Types

/// Error severity levels for user interface decisions
public enum ErrorSeverity {
    case low     // Minor issues, app can continue normally
    case medium  // Some functionality affected, but app usable
    case high    // Major issues, user action required
    case critical // App cannot continue, requires immediate attention
}

// MARK: - User Error Context

/// Context information for displaying errors to users
public struct UserErrorContext {
    public let message: String
    public let suggestions: [String]
    public let isRecoverable: Bool
    public let severity: ErrorSeverity
    
    public init(message: String, suggestions: [String], isRecoverable: Bool, severity: ErrorSeverity) {
        self.message = message
        self.suggestions = suggestions
        self.isRecoverable = isRecoverable
        self.severity = severity
    }
}

// MARK: - Convenience Extensions

extension OCRErrorHandler {
    
    /// Get complete user error context for an error
    /// - Parameter error: The error to process
    /// - Returns: Complete context for displaying to the user
    public func getUserErrorContext(for error: Error) -> UserErrorContext {
        let message = getUserFriendlyMessage(for: error)
        let suggestions = getRecoverySuggestions(for: error)
        let isRecoverable = isRecoverable(error)
        let severity = getSeverity(of: error)
        
        return UserErrorContext(
            message: message,
            suggestions: suggestions,
            isRecoverable: isRecoverable,
            severity: severity
        )
    }
}