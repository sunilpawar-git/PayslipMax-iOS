import Foundation
import SwiftData
import PDFKit
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

// MARK: - Mock Text Extraction Service
class MockTextExtractionService: TextExtractionServiceProtocol {
    var mockText: String = "This is mock extracted text"
    
    // Track method calls for verification in tests
    var extractTextFromDocumentCallCount = 0
    var extractTextFromPageCallCount = 0
    var extractDetailedTextCallCount = 0
    var logTextExtractionDiagnosticsCallCount = 0
    var hasTextContentCallCount = 0
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        extractTextFromDocumentCallCount += 1
        return mockText
    }
    
    func extractText(from page: PDFPage) -> String {
        extractTextFromPageCallCount += 1
        return mockText
    }
    
    func extractDetailedText(from pdfDocument: PDFDocument) -> String {
        extractDetailedTextCallCount += 1
        return mockText + "\n[DETAILED]"
    }
    
    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument) {
        logTextExtractionDiagnosticsCallCount += 1
    }
    
    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool {
        hasTextContentCallCount += 1
        return !mockText.isEmpty
    }
    
    func reset() {
        mockText = "This is mock extracted text"
        extractTextFromDocumentCallCount = 0
        extractTextFromPageCallCount = 0
        extractDetailedTextCallCount = 0
        logTextExtractionDiagnosticsCallCount = 0
        hasTextContentCallCount = 0
    }
}

// MARK: - Mock Payslip Validation Service
class MockPayslipValidationService: PayslipValidationServiceProtocol {
    // MARK: - Properties
    
    var validateStructureCallCount = 0
    var validateContentCallCount = 0
    var isPasswordProtectedCallCount = 0
    var validatePayslipCallCount = 0
    var deepValidatePayslipCallCount = 0
    var structureIsValid = true
    var contentIsValid = true
    var contentConfidence = 0.8
    var isPasswordProtected = false
    var lastValidatedData: Data?
    var lastValidatedText: String?
    var payslipIsValid = true
    
    // MARK: - Initialization
    
    init(structureIsValid: Bool = true, contentIsValid: Bool = true, isPasswordProtected: Bool = false, payslipIsValid: Bool = true) {
        self.structureIsValid = structureIsValid
        self.contentIsValid = contentIsValid
        self.isPasswordProtected = isPasswordProtected
        self.payslipIsValid = payslipIsValid
    }
    
    // MARK: - Methods
    
    func reset() {
        validateStructureCallCount = 0
        validateContentCallCount = 0
        isPasswordProtectedCallCount = 0
        validatePayslipCallCount = 0
        deepValidatePayslipCallCount = 0
        lastValidatedData = nil
        lastValidatedText = nil
    }
    
    func validatePDFStructure(_ data: Data) -> Bool {
        validateStructureCallCount += 1
        lastValidatedData = data
        return structureIsValid
    }
    
    func validatePayslipContent(_ text: String) -> PayslipContentValidationResult {
        validateContentCallCount += 1
        lastValidatedText = text
        
        return PayslipContentValidationResult(
            isValid: contentIsValid,
            confidence: contentConfidence,
            detectedFields: contentIsValid ? ["name", "month", "year", "earnings", "deductions"] : [],
            missingRequiredFields: contentIsValid ? [] : ["name", "month", "year", "earnings", "deductions"]
        )
    }
    
    func isPDFPasswordProtected(_ data: Data) -> Bool {
        isPasswordProtectedCallCount += 1
        lastValidatedData = data
        return isPasswordProtected
    }
    
    func validatePayslip(_ payslip: any PayslipProtocol) -> BasicPayslipValidationResult {
        validatePayslipCallCount += 1
        return BasicPayslipValidationResult(
            isValid: payslipIsValid,
            errors: payslipIsValid ? [] : [.missingRequiredField("month"), .missingRequiredField("year")]
        )
    }
    
    func deepValidatePayslip(_ payslip: any PayslipProtocol) -> PayslipDeepValidationResult {
        deepValidatePayslipCallCount += 1
        
        let basicValidation = BasicPayslipValidationResult(
            isValid: payslipIsValid,
            errors: payslipIsValid ? [] : [.missingRequiredField("month"), .missingRequiredField("year")]
        )
        
        var pdfValidationSuccess = false
        var pdfValidationMessage = "No PDF data available"
        var contentValidation: PayslipContentValidationResult? = nil
        
        if payslip.pdfData != nil {
            pdfValidationSuccess = structureIsValid
            pdfValidationMessage = structureIsValid ? "PDF structure is valid" : "PDF structure is invalid"
            
            if structureIsValid {
                contentValidation = PayslipContentValidationResult(
                    isValid: contentIsValid,
                    confidence: contentConfidence,
                    detectedFields: contentIsValid ? ["name", "month", "year", "earnings", "deductions"] : [],
                    missingRequiredFields: contentIsValid ? [] : ["name", "month", "year", "earnings", "deductions"]
                )
            }
        }
        
        return PayslipDeepValidationResult(
            basicValidation: basicValidation,
            pdfValidationSuccess: pdfValidationSuccess,
            pdfValidationMessage: pdfValidationMessage,
            contentValidation: contentValidation
        )
    }
}

// MARK: - Mock Payslip Processor
class MockPayslipProcessor: PayslipProcessorProtocol {
    // MARK: - Properties
    
    var processCallCount = 0
    var processPayslipCalled = false
    var processPayslipWithTextCalled = 0
    var canProcessCallCount = 0
    var lastProcessedText: String?
    var shouldThrowError = false
    var payslipToReturn: PayslipItem?
    var shouldSucceed = true
    var confidenceScore: Double
    var handlesFormat: PayslipFormat = .military
    
    // MARK: - Initialization
    
    init(shouldSucceed: Bool = true, confidenceScore: Double = 0.8) {
        self.shouldSucceed = shouldSucceed
        self.confidenceScore = confidenceScore
    }
    
    // MARK: - Methods
    
    func reset() {
        processCallCount = 0
        processPayslipCalled = false
        processPayslipWithTextCalled = 0
        canProcessCallCount = 0
        lastProcessedText = nil
        shouldThrowError = false
        payslipToReturn = nil
        handlesFormat = .military
    }
    
    func processPayslip(from text: String) throws -> PayslipItem {
        processCallCount += 1
        processPayslipCalled = true
        processPayslipWithTextCalled += 1
        lastProcessedText = text
        
        if shouldThrowError {
            throw NSError(domain: "MockProcessor", code: 1, userInfo: nil)
        }
        
        let updatedPayslip = self.payslipToReturn ?? PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2023,
            credits: 1000.0,
            debits: 200.0,
            dsop: 50.0,
            tax: 100.0,
            name: "Test Employee",
            accountNumber: "123456",
            panNumber: "ABCDE1234F",
            pdfData: Data()
        )
        
        return updatedPayslip
    }
    
    func canProcess(text: String) -> Double {
        canProcessCallCount += 1
        lastProcessedText = text
        return confidenceScore
    }
}

// MARK: - Mock Payslip Processor Factory
class MockPayslipProcessorFactory {
    // MARK: - Properties
    
    var processors: [PayslipProcessorProtocol] = []
    var getProcessorCallCount = 0
    var lastRequestedFormat: PayslipFormat?
    var lastRequestedText: String?
    var processorToReturn: PayslipProcessorProtocol?
    
    // MARK: - Initialization
    
    init(processors: [PayslipProcessorProtocol] = [], processorToReturn: PayslipProcessorProtocol? = nil) {
        self.processors = processors
        self.processorToReturn = processorToReturn ?? MockPayslipProcessor()
    }
    
    // MARK: - Methods
    
    func reset() {
        getProcessorCallCount = 0
        lastRequestedFormat = nil
        lastRequestedText = nil
    }
    
    func getProcessor(for text: String) -> PayslipProcessorProtocol {
        getProcessorCallCount += 1
        lastRequestedText = text
        return processorToReturn!
    }
    
    func getProcessor(for format: PayslipFormat) -> PayslipProcessorProtocol {
        getProcessorCallCount += 1
        lastRequestedFormat = format
        return processorToReturn!
    }
    
    func getAllProcessors() -> [PayslipProcessorProtocol] {
        return processors
    }
} 