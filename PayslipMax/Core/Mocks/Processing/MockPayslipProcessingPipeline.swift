import Foundation

/// Mock implementation of the PayslipProcessingPipeline for testing purposes.
///
/// This mock service simulates the complete payslip processing pipeline with
/// controllable behavior for each stage of processing. It provides configurable
/// success/failure modes for validation, extraction, detection, and processing.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockPayslipProcessingPipeline: PayslipProcessingPipeline, @unchecked Sendable {
    
    // MARK: - Control Properties
    
    /// Controls whether validation succeeds
    var shouldValidateSuccessfully = true
    
    /// Controls whether text extraction succeeds
    var shouldExtractSuccessfully = true
    
    /// Controls whether format detection succeeds
    var shouldDetectSuccessfully = true
    
    /// Controls whether processing succeeds
    var shouldProcessSuccessfully = true
    
    // MARK: - Return Value Properties
    
    /// The data to return from validation
    var dataToReturn = Data()
    
    /// The text to return from extraction
    var textToReturn = "Mock extracted text"
    
    /// The format to return from detection
    var formatToReturn: PayslipFormat = .corporate
    
    /// The payslip to return from processing
    var payslipToReturn: PayslipItem?
    
    /// Error to return when failing
    var errorToReturn: PDFProcessingError = .processingFailed
    
    // MARK: - Initialization
    
    /// Creates a mock pipeline with optional custom payslip.
    /// - Parameter payslipToReturn: Custom payslip to return (optional)
    init(payslipToReturn: PayslipItem? = nil) {
        self.payslipToReturn = payslipToReturn
        
        // Create default payslip if none provided
        if self.payslipToReturn == nil {
            self.payslipToReturn = PayslipItem(
                id: UUID(),
                timestamp: Date(),
                month: "January",
                year: 2023,
                credits: 10000.0,
                debits: 2000.0,
                dsop: 500.0,
                tax: 1000.0,
                name: "Mock User",
                accountNumber: "123456789",
                panNumber: "ABCDE1234F",
                pdfData: Data()
            )
        }
    }
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        shouldValidateSuccessfully = true
        shouldExtractSuccessfully = true
        shouldDetectSuccessfully = true
        shouldProcessSuccessfully = true
    }
    
    // MARK: - PayslipProcessingPipeline Implementation
    
    func validatePDF(_ data: Data) async -> Result<Data, PDFProcessingError> {
        if shouldValidateSuccessfully {
            return .success(dataToReturn.isEmpty ? data : dataToReturn)
        } else {
            return .failure(errorToReturn)
        }
    }
    
    func extractText(_ data: Data) async -> Result<(Data, String), PDFProcessingError> {
        if shouldExtractSuccessfully {
            return .success((data, textToReturn))
        } else {
            return .failure(errorToReturn)
        }
    }
    
    func detectFormat(_ data: Data, text: String) async -> Result<(Data, String, PayslipFormat), PDFProcessingError> {
        if shouldDetectSuccessfully {
            return .success((data, text, formatToReturn))
        } else {
            return .failure(errorToReturn)
        }
    }
    
    func processPayslip(_ data: Data, text: String, format: PayslipFormat) async -> Result<PayslipItem, PDFProcessingError> {
        if shouldProcessSuccessfully {
            guard let payslip = payslipToReturn else {
                return .failure(.processingFailed)
            }
            
            // Create a new payslip with the provided data
            let payslipCopy = PayslipItem(
                id: payslip.id,
                timestamp: payslip.timestamp,
                month: payslip.month,
                year: payslip.year,
                credits: payslip.credits,
                debits: payslip.debits,
                dsop: payslip.dsop,
                tax: payslip.tax,
                name: payslip.name,
                accountNumber: payslip.accountNumber,
                panNumber: payslip.panNumber,
                pdfData: data
            )
            return .success(payslipCopy)
        } else {
            return .failure(errorToReturn)
        }
    }
    
    func executePipeline(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        // Simulate going through the whole pipeline
        if !shouldValidateSuccessfully {
            return .failure(errorToReturn)
        }
        
        if !shouldExtractSuccessfully {
            return .failure(errorToReturn)
        }
        
        if !shouldDetectSuccessfully {
            return .failure(errorToReturn)
        }
        
        if !shouldProcessSuccessfully {
            return .failure(errorToReturn)
        }
        
        guard let payslip = payslipToReturn else {
            return .failure(.processingFailed)
        }
        
        // Create a new payslip with the provided data
        let payslipCopy = PayslipItem(
            id: payslip.id,
            timestamp: payslip.timestamp,
            month: payslip.month,
            year: payslip.year,
            credits: payslip.credits,
            debits: payslip.debits,
            dsop: payslip.dsop,
            tax: payslip.tax,
            name: payslip.name,
            accountNumber: payslip.accountNumber,
            panNumber: payslip.panNumber,
            pdfData: data
        )
        return .success(payslipCopy)
    }
} 