import Foundation
import SwiftData
import PDFKit
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI
@testable import PayslipMax

// MARK: - Mock Payslip Processing Pipeline
final class MockPayslipProcessingPipeline: PayslipProcessingPipeline, @unchecked Sendable {
    // MARK: - Properties
    
    /// Controls whether validation succeeds
    var shouldValidateSuccessfully = true
    
    /// Controls whether text extraction succeeds
    var shouldExtractSuccessfully = true
    
    /// Controls whether format detection succeeds
    var shouldDetectSuccessfully = true
    
    /// Controls whether processing succeeds
    var shouldProcessSuccessfully = true
    
    /// The data to return from validation
    var dataToReturn = Data()
    
    /// The text to return from extraction
    var textToReturn = "Mock extracted text"
    
    /// The format to return from detection
    var formatToReturn: PayslipFormat = .corporate
    
    /// The payslip to return from processing
    var payslipToReturn: PayslipMax.PayslipItem?
    
    /// Error to return when failing
    var errorToReturn: PDFProcessingError = .processingFailed
    
    /// Times each method was called
    var validatePDFCallCount = 0
    var extractTextCallCount = 0
    var detectFormatCallCount = 0
    var processPayslipCallCount = 0
    var executePipelineCallCount = 0
    
    /// Last values passed to methods
    var lastDataPassedToValidate: Data?
    var lastDataPassedToExtract: Data?
    var lastDataPassedToDetect: Data?
    var lastTextPassedToDetect: String?
    var lastDataPassedToProcess: Data?
    var lastTextPassedToProcess: String?
    var lastFormatPassedToProcess: PayslipFormat?
    var lastDataPassedToPipeline: Data?
    
    // MARK: - Initialization
    
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
    
    // MARK: - Methods
    
    func reset() {
        validatePDFCallCount = 0
        extractTextCallCount = 0
        detectFormatCallCount = 0
        processPayslipCallCount = 0
        executePipelineCallCount = 0
        
        lastDataPassedToValidate = nil
        lastDataPassedToExtract = nil
        lastDataPassedToDetect = nil
        lastTextPassedToDetect = nil
        lastDataPassedToProcess = nil
        lastTextPassedToProcess = nil
        lastFormatPassedToProcess = nil
        lastDataPassedToPipeline = nil
        
        shouldValidateSuccessfully = true
        shouldExtractSuccessfully = true
        shouldDetectSuccessfully = true
        shouldProcessSuccessfully = true
    }
    
    func validatePDF(_ data: Data) async -> Result<Data, PDFProcessingError> {
        validatePDFCallCount += 1
        lastDataPassedToValidate = data
        
        if shouldValidateSuccessfully {
            return .success(dataToReturn.isEmpty ? data : dataToReturn)
        } else {
            return .failure(errorToReturn)
        }
    }
    
    func extractText(_ data: Data) async -> Result<(Data, String), PDFProcessingError> {
        extractTextCallCount += 1
        lastDataPassedToExtract = data
        
        if shouldExtractSuccessfully {
            return .success((data, textToReturn))
        } else {
            return .failure(errorToReturn)
        }
    }
    
    func detectFormat(_ data: Data, text: String) async -> Result<(Data, String, PayslipFormat), PDFProcessingError> {
        detectFormatCallCount += 1
        lastDataPassedToDetect = data
        lastTextPassedToDetect = text
        
        if shouldDetectSuccessfully {
            return .success((data, text, formatToReturn))
        } else {
            return .failure(errorToReturn)
        }
    }
    
    func processPayslip(_ data: Data, text: String, format: PayslipFormat) async -> Result<PayslipItem, PDFProcessingError> {
        processPayslipCallCount += 1
        lastDataPassedToProcess = data
        lastTextPassedToProcess = text
        lastFormatPassedToProcess = format
        
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
    
    func executePipeline(_ data: Data) async -> Result<PayslipMax.PayslipItem, PayslipMax.PDFProcessingError> {
        executePipelineCallCount += 1
        lastDataPassedToPipeline = data
        
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
        let payslipCopy = PayslipMax.PayslipItem(
        return .success(payslipCopy)
    }
} 