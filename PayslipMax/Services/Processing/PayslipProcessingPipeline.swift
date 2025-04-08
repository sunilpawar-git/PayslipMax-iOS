import Foundation
import PDFKit
import UIKit

/// Protocol that defines a processing pipeline for payslips
@MainActor protocol PayslipProcessingPipeline {
    /// Validates the PDF data to ensure it's properly formatted
    /// - Parameter data: The PDF data to validate
    /// - Returns: Success with the data or failure with an error
    func validatePDF(_ data: Data) async -> Result<Data, PDFProcessingError>
    
    /// Extracts text from the PDF data
    /// - Parameter data: The validated PDF data
    /// - Returns: Success with the extracted text or failure with an error
    func extractText(_ data: Data) async -> Result<(Data, String), PDFProcessingError>
    
    /// Detects the format of the payslip based on the extracted text
    /// - Parameter text: The extracted text from the PDF
    /// - Returns: Success with the detected format and original data or failure with an error
    func detectFormat(_ data: Data, text: String) async -> Result<(Data, String, PayslipFormat), PDFProcessingError>
    
    /// Processes the payslip based on the detected format
    /// - Parameters:
    ///   - data: The PDF data
    ///   - text: The extracted text
    ///   - format: The detected payslip format
    /// - Returns: Success with the processed payslip or failure with an error
    func processPayslip(_ data: Data, text: String, format: PayslipFormat) async -> Result<PayslipItem, PDFProcessingError>
    
    /// Executes the full pipeline from validation to processing
    /// - Parameter data: The PDF data to process
    /// - Returns: Success with the processed payslip or failure with an error
    func executePipeline(_ data: Data) async -> Result<PayslipItem, PDFProcessingError>
} 