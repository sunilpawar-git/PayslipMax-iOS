import Foundation
import SwiftUI
import Combine

/// A handler for error management and display
@MainActor
class ErrorHandler: ObservableObject {
    // MARK: - Published Properties
    
    /// The error message to display to the user.
    @Published var errorMessage: String?
    
    /// The error to display to the user.
    @Published var error: AppError?
    
    /// The error type.
    @Published var errorType: AppError?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Error Handling Methods
    
    /// Handles an error by setting the appropriate error properties.
    /// - Parameter error: The error to handle.
    func handleError(_ error: Error) {
        print("[ErrorHandler] Handling error: \(error.localizedDescription)")
        
        if let appError = error as? AppError {
            self.error = appError
            self.errorMessage = appError.localizedDescription
            self.errorType = appError
        } else {
            self.errorMessage = error.localizedDescription
            
            // Create an AppError from the generic error
            self.error = AppError.message(error.localizedDescription)
        }
    }
    
    /// Handles an error specific to PDF processing.
    /// - Parameter error: The PDF-related error to handle.
    func handlePDFError(_ error: Error) {
        print("[ErrorHandler] Handling PDF error: \(error.localizedDescription)")
        
        // Check for password-protected PDF error types
        if let pdfProcessingError = error as? PDFProcessingError, 
           pdfProcessingError == .passwordProtected {
            print("[ErrorHandler] Detected password protected PDF - delegating to password handler")
            // Note: We're not directly using the password handler here since we don't have the PDF data
            // Instead, we're creating an AppError that will be handled by the UI layer
            showError(.passwordProtectedPDF("Please enter the password to view this PDF"))
            return
        }
        
        // Check for PDFService errors
        if let pdfServiceError = error as? PDFServiceError {
            switch pdfServiceError {
            case .incorrectPassword:
                showError(.passwordProtectedPDF("The password provided is incorrect"))
                return
            case .militaryPDFNotSupported:
                showError(.passwordProtectedPDF("This is a military PDF. Please enter your service ID or PCDA password"))
                return
            case .unsupportedEncryptionMethod:
                showError(.invalidPDFFormat)
                return
            default:
                break
            }
        }
        
        // Check if the error contains information about password protection
        let errorDescription = error.localizedDescription.lowercased()
        if errorDescription.contains("password") || 
           errorDescription.contains("protected") || 
           errorDescription.contains("encrypted") {
            print("[ErrorHandler] Error description suggests password protection: \(errorDescription)")
            showError(.passwordProtectedPDF("This PDF requires a password"))
            return
        }
        
        if let payslipError = error as? PayslipError {
            // Map PayslipError to a user-friendly message
            switch payslipError {
            case .invalidPDFData:
                errorMessage = "The PDF data is invalid or corrupted."
            case .unableToProcessPDF:
                errorMessage = "Unable to process the PDF. The format may not be supported."
            case .invalidData:
                errorMessage = "The payslip data is invalid."
            case .invalidFormat:
                errorMessage = "The payslip format is not recognized."
            case .unsupportedFormat:
                errorMessage = "This payslip format is not supported."
            case .emptyDocument:
                errorMessage = "The document appears to be empty."
            case .conversionFailed:
                errorMessage = "Failed to convert the document."
            case .processingTimeout:
                errorMessage = "Processing timed out. Please try again."
            default:
                errorMessage = payslipError.localizedDescription
            }
            
            // Set the error type
            self.error = AppError.pdfProcessingFailed(errorMessage ?? "PDF processing failed")
        } else if let appError = error as? AppError {
            // Handle AppError directly
            showError(appError)
        } else {
            // Handle generic errors
            handleError(error)
        }
    }
    
    /// Clears the current error state.
    func clearError() {
        errorMessage = nil
        error = nil
        errorType = nil
    }
    
    /// Helper method to show an AppError.
    /// - Parameter appError: The AppError to display.
    private func showError(_ appError: AppError) {
        self.error = appError
        self.errorMessage = appError.userMessage
        self.errorType = appError
    }
} 