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
} 