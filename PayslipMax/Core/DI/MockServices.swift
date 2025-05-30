import Foundation
import SwiftData
import PDFKit
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

// TODO: REFACTORING - This file is being refactored according to the plan in MockServicesRefactoring.md
// The file should be broken down into smaller, more focused mock service files.
// Current issues:
// 1. Excessive Size: This file is 1163 lines long with multiple mock implementations
// 2. Lack of Organization: Multiple mock services in one file makes it difficult to locate specific mocks
// 3. Low Cohesion: Unrelated services are grouped together
// 4. Maintenance Challenges: Changes to one mock might affect others
//
// REFACTORING PROGRESS:
// - MockError moved to PayslipMaxTests/Mocks/Core/MockError.swift
// - MockSecurityService moved to PayslipMaxTests/Mocks/Core/MockSecurityService.swift
// - MockDataService moved to PayslipMaxTests/Mocks/Core/MockDataService.swift
// - MockPDFService copied to PayslipMaxTests/Mocks/PDF/MockPDFService.swift
// - MockPDFExtractor copied to PayslipMaxTests/Mocks/PDF/MockPDFExtractor.swift

// MARK: - Mock Error Types
// Moved to PayslipMaxTests/Mocks/Core/MockError.swift
enum MockError: LocalizedError, Equatable {
    case initializationFailed
    case encryptionFailed
    case decryptionFailed
    case authenticationFailed
    case saveFailed
    case fetchFailed
    case deleteFailed
    case clearAllDataFailed
    case unlockFailed
    case setupPINFailed
    case verifyPINFailed
    case clearFailed
    case processingFailed
    case incorrectPassword
    case extractionFailed
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed: return "Initialization failed"
        case .encryptionFailed: return "Encryption failed"
        case .decryptionFailed: return "Decryption failed"
        case .authenticationFailed: return "Authentication failed"
        case .saveFailed: return "Save failed"
        case .fetchFailed: return "Fetch failed"
        case .deleteFailed: return "Delete failed"
        case .clearAllDataFailed: return "Clear all data failed"
        case .unlockFailed: return "Unlock failed"
        case .setupPINFailed: return "Setup PIN failed"
        case .verifyPINFailed: return "Verify PIN failed"
        case .clearFailed: return "Clear failed"
        case .processingFailed: return "Processing failed"
        case .incorrectPassword: return "Incorrect password"
        case .extractionFailed: return "Extraction failed"
        }
    }
}

// MARK: - Mock Security Service
class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = false
    var shouldAuthenticateSuccessfully = true
    var shouldFail = false
    var encryptionResult: Data?
    var decryptionResult: Data?
    var isBiometricAuthAvailable: Bool = true
    
    // Track method calls for verification in tests
    var initializeCallCount = 0
    var encryptCallCount = 0
    var decryptCallCount = 0
    var authenticateCount = 0
    var setupPINCallCount = 0
    var verifyPINCallCount = 0
    
    func reset() {
        isInitialized = false
        shouldAuthenticateSuccessfully = true
        shouldFail = false
        encryptionResult = nil
        decryptionResult = nil
        isBiometricAuthAvailable = true
        initializeCallCount = 0
        encryptCallCount = 0
        decryptCallCount = 0
        authenticateCount = 0
        setupPINCallCount = 0
        verifyPINCallCount = 0
    }
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        authenticateCount += 1
        if shouldFail {
            throw MockError.authenticationFailed
        }
        return shouldAuthenticateSuccessfully
    }
    
    func setupPIN(pin: String) async throws {
        setupPINCallCount += 1
        if shouldFail {
            throw MockError.setupPINFailed
        }
    }
    
    func verifyPIN(pin: String) async throws -> Bool {
        verifyPINCallCount += 1
        if shouldFail {
            throw MockError.verifyPINFailed
        }
        return pin == "1234" // Simple mock implementation
    }
    
    func encryptData(_ data: Data) async throws -> Data {
        encryptCallCount += 1
        if shouldFail {
            throw MockError.encryptionFailed
        }
        if let result = encryptionResult {
            return result
        }
        // Return a modified version of the data to simulate encryption
        var modifiedData = data
        modifiedData.append(contentsOf: [0xFF, 0xEE, 0xDD, 0xCC]) // Add some bytes
        return modifiedData
    }
    
    func decryptData(_ data: Data) async throws -> Data {
        decryptCallCount += 1
        if shouldFail {
            throw MockError.decryptionFailed
        }
        if let result = decryptionResult {
            return result
        }
        // Remove the extra bytes that were added during encryption
        if data.count >= 4 {
            return data.dropLast(4)
        }
        // Fallback if the data is too short
        return data
    }
}

// MARK: - Mock Data Service
// Moved to PayslipMaxTests/Mocks/Core/MockDataService.swift

// MARK: - Mock PDF Service
// NOTE: Currently maintaining this implementation while figuring out the right cross-module approach
class MockPDFService: PDFServiceProtocol {
    var shouldFail = false
    var extractResult: [String: String] = [:]
    var unlockResult: Data?
    var isInitialized: Bool = false
    
    // Track method calls for verification in tests
    var extractCallCount = 0
    var unlockCallCount = 0
    var processCallCount = 0
    var initializeCallCount = 0
    var detectFormatCallCount = 0
    var validateContentCallCount = 0
    var validationCallCount = 0
    var mockValidationResult = PayslipContentValidationResult(
        isValid: true,
        confidence: 1.0,
        detectedFields: [],
        missingRequiredFields: []
    )
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func process(_ url: URL) async throws -> Data {
        processCallCount += 1
        if shouldFail {
            throw MockError.processingFailed
        }
        return Data()
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        unlockCallCount += 1
        if shouldFail {
            throw MockError.unlockFailed
        }
        if password != "correct" {
            throw MockError.incorrectPassword
        }
        if let result = unlockResult {
            return result
        }
        return data
    }
    
    func extract(_ data: Data) -> [String: String] {
        extractCallCount += 1
        if shouldFail {
            return [:]
        }
        return extractResult
    }
    
    func detectFormat(_ data: Data) -> PayslipFormat {
        detectFormatCallCount += 1
        return .pcda
    }
    
    func validateContent(_ data: Data) -> PayslipContentValidationResult {
        validateContentCallCount += 1
        if shouldFail {
            return PayslipContentValidationResult(
                isValid: false,
                confidence: 0.0,
                detectedFields: [],
                missingRequiredFields: ["Mock validation failed"]
            )
        }
        return mockValidationResult
    }
    
    func validatePayslipData(_ data: [String: String]) -> PayslipContentValidationResult {
        validationCallCount += 1
        if shouldFail {
            return PayslipContentValidationResult(
                isValid: false,
                confidence: 0.0,
                detectedFields: [],
                missingRequiredFields: ["Mock validation failed"]
            )
        }
        return mockValidationResult
    }
    
    func reset() {
        shouldFail = false
        extractResult.removeAll()
        unlockResult = nil
        isInitialized = false
        extractCallCount = 0
        unlockCallCount = 0
        processCallCount = 0
        initializeCallCount = 0
        detectFormatCallCount = 0
        validateContentCallCount = 0
        validationCallCount = 0
        mockValidationResult = PayslipContentValidationResult(
            isValid: true,
            confidence: 1.0,
            detectedFields: [],
            missingRequiredFields: []
        )
    }
}

// MARK: - Mock PDF Processing Service
class MockPDFProcessingService: PDFProcessingServiceProtocol {
    var isInitialized: Bool = false
    var shouldFail = false
    var mockPayslipItem: PayslipItem?
    
    // Track method calls for verification in tests
    var initializeCallCount = 0
    var processPDFCallCount = 0
    var processPDFDataCallCount = 0
    var isPasswordProtectedCallCount = 0
    var unlockPDFCallCount = 0
    var processScannedImageCallCount = 0
    var detectPayslipFormatCallCount = 0
    var validatePayslipContentCallCount = 0
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func processPDF(from url: URL) async -> Result<Data, PDFProcessingError> {
        processPDFCallCount += 1
        if shouldFail {
            return .failure(.parsingFailed("Mock processing failed"))
        }
        return .success(Data())
    }
    
    func processPDFData(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        processPDFDataCallCount += 1
        if shouldFail {
            return .failure(.parsingFailed("Mock processing failed"))
        }
        if let item = mockPayslipItem {
            return .success(item)
        }
        return .success(PayslipItemFactory.createSample() as! PayslipItem)
    }
    
    func isPasswordProtected(_ data: Data) -> Bool {
        isPasswordProtectedCallCount += 1
        return false
    }
    
    func unlockPDF(_ data: Data, password: String) async -> Result<Data, PDFProcessingError> {
        unlockPDFCallCount += 1
        if shouldFail {
            return .failure(.incorrectPassword)
        }
        return .success(data)
    }
    
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError> {
        processScannedImageCallCount += 1
        if shouldFail {
            return .failure(.parsingFailed("Mock processing failed"))
        }
        if let item = mockPayslipItem {
            return .success(item)
        }
        return .failure(.invalidData)
    }
    
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        detectPayslipFormatCallCount += 1
        return .pcda
    }
    
    func validatePayslipContent(_ data: Data) -> PayslipContentValidationResult {
        validatePayslipContentCallCount += 1
        if shouldFail {
            return PayslipContentValidationResult(
                isValid: false,
                confidence: 0.0,
                detectedFields: [],
                missingRequiredFields: ["Mock validation failed"]
            )
        }
        return PayslipContentValidationResult(
            isValid: true,
            confidence: 1.0,
            detectedFields: [],
            missingRequiredFields: []
        )
    }
    
    func reset() {
        isInitialized = false
        shouldFail = false
        mockPayslipItem = nil
        initializeCallCount = 0
        processPDFCallCount = 0
        processPDFDataCallCount = 0
        isPasswordProtectedCallCount = 0
        unlockPDFCallCount = 0
        processScannedImageCallCount = 0
        detectPayslipFormatCallCount = 0
        validatePayslipContentCallCount = 0
    }
}

// MARK: - Mock PDF Extractor
// Moved to PayslipMaxTests/Mocks/PDF/MockPDFExtractor.swift
// IMPORTANT: Keep this implementation available for TestDIContainer to use
class MockPDFExtractor: PDFExtractorProtocol {
    var shouldFail = false
    var mockPayslipItem: PayslipItem?
    var mockText = "This is mock extracted text"
    
    // Track method calls for verification in tests
    var extractPayslipDataFromPDFCallCount = 0
    var extractPayslipDataFromTextCallCount = 0
    var extractTextCallCount = 0
    var getAvailableParsersCallCount = 0
    
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        extractPayslipDataFromPDFCallCount += 1
        if shouldFail {
            return nil
        }
        if let item = mockPayslipItem {
            return item
        }
        return PayslipItemFactory.createSample() as? PayslipItem
    }
    
    func extractPayslipData(from text: String) -> PayslipItem? {
        extractPayslipDataFromTextCallCount += 1
        if shouldFail {
            return nil
        }
        if let item = mockPayslipItem {
            return item
        }
        return PayslipItemFactory.createSample() as? PayslipItem
    }
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        extractTextCallCount += 1
        if shouldFail {
            return ""
        }
        return mockText
    }
    
    func getAvailableParsers() -> [String] {
        getAvailableParsersCallCount += 1
        return ["MockParser1", "MockParser2"]
    }
    
    func reset() {
        shouldFail = false
        mockPayslipItem = nil
        mockText = "This is mock extracted text"
        extractPayslipDataFromPDFCallCount = 0
        extractPayslipDataFromTextCallCount = 0
        extractTextCallCount = 0
        getAvailableParsersCallCount = 0
    }
}

// MARK: - Mock Payslip Format Detection Service
// NOTE: This has been moved to PayslipMaxTests/Mocks/Payslip/MockPayslipFormatDetectionService.swift
// Keeping implementation here until refactoring is complete
class MockPayslipFormatDetectionService: PayslipFormatDetectionServiceProtocol {
    var mockFormat: PayslipFormat = .standard
    
    // Track method calls for verification in tests
    var detectFormatFromDataCallCount = 0
    var detectFormatFromTextCallCount = 0
    
    func detectFormat(_ data: Data) -> PayslipFormat {
        detectFormatFromDataCallCount += 1
        return mockFormat
    }
    
    func detectFormat(fromText text: String) -> PayslipFormat {
        detectFormatFromTextCallCount += 1
        return mockFormat
    }
    
    func reset() {
        mockFormat = .standard
        detectFormatFromDataCallCount = 0
        detectFormatFromTextCallCount = 0
    }
}

// MARK: - Mock Text Extraction Service
/*
 * Moved to PayslipMaxTests/Mocks/PDF/MockTextExtractionService.swift
 * Keeping implementation here until refactoring is complete for DIContainer
 */
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

/// Mock implementation of PayslipValidationServiceProtocol for testing
// NOTE: This has been moved to PayslipMaxTests/Mocks/Payslip/MockPayslipValidationService.swift
// Keeping implementation here until refactoring is complete
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

/// Mock implementation of PayslipProcessorProtocol for testing
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

/// Mock implementation of PayslipProcessorFactory for testing
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

/// Mock implementation of PDFTextExtractionServiceProtocol for testing
class MockPDFTextExtractionService: PDFTextExtractionServiceProtocol {
    // MARK: - Properties
    
    var extractTextCallCount = 0
    var shouldSucceed = true
    var textToReturn = "Mock PDF content for testing purposes"
    
    // MARK: - Initialization
    
    init(shouldSucceed: Bool = true, textToReturn: String? = nil) {
        self.shouldSucceed = shouldSucceed
        if let text = textToReturn {
            self.textToReturn = text
        }
    }
    
    // MARK: - Methods
    
    func reset() {
        extractTextCallCount = 0
    }
    
    func extractText(from data: Data) throws -> String {
        extractTextCallCount += 1
        
        if !shouldSucceed {
            throw PDFProcessingError.textExtractionFailed
        }
        
        return textToReturn
    }
    
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
        extractTextCallCount += 1
        
        if !shouldSucceed {
            return nil
        }
        
        // Simulate callback if provided
        if let callback = callback {
            callback(textToReturn, 1, 1)
        }
        
        return textToReturn
    }
    
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        extractTextCallCount += 1
        
        if !shouldSucceed {
            return nil
        }
        
        return textToReturn
    }
    
    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        extractTextCallCount += 1
        
        if !shouldSucceed {
            return nil
        }
        
        return textToReturn
    }
    
    func currentMemoryUsage() -> UInt64 {
        return 1024 * 1024 // Return 1MB as mock memory usage
    }
}

/// Mock implementation of PDFParsingCoordinatorProtocol for testing
class MockPDFParsingCoordinator: PDFParsingCoordinatorProtocol {
    // MARK: - Properties
    
    var extractFullTextCallCount = 0
    var parsePayslipCallCount = 0
    var parsePayslipUsingParserCallCount = 0
    var selectBestParserCallCount = 0
    var lastDocument: PDFDocument?
    var lastText: String?
    var lastParserName: String?
    var textToReturn = "Mock PDF text for testing purposes"
    var payslipToReturn: PayslipItem?
    var parserToReturn: PayslipParser?
    var shouldThrowError = false
    
    // MARK: - Initialization
    
    init(payslipToReturn: PayslipItem? = nil, parserToReturn: PayslipParser? = nil) {
        self.payslipToReturn = payslipToReturn
        self.parserToReturn = parserToReturn
        
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
        extractFullTextCallCount = 0
        parsePayslipCallCount = 0
        parsePayslipUsingParserCallCount = 0
        selectBestParserCallCount = 0
        lastDocument = nil
        lastText = nil
        lastParserName = nil
        shouldThrowError = false
    }
    
    func extractFullText(from document: PDFDocument) -> String? {
        extractFullTextCallCount += 1
        lastDocument = document
        return textToReturn
    }
    
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipItem? {
        parsePayslipCallCount += 1
        lastDocument = pdfDocument
        
        if shouldThrowError {
            throw MockError.processingFailed
        }
        return payslipToReturn
    }
    
    func parsePayslip(pdfDocument: PDFDocument, using parserName: String) async throws -> PayslipItem? {
        parsePayslipUsingParserCallCount += 1
        lastDocument = pdfDocument
        lastParserName = parserName
        
        if shouldThrowError {
            throw MockError.processingFailed
        }
        
        // Basic mock logic: return the standard payslip if the parser name is known, otherwise nil
        if parserName == parserToReturn?.name || parserName == "MockParser1" {
            return payslipToReturn
        } else {
            // Simulate parser not found or failure
            return nil
        }
    }
    
    func selectBestParser(for text: String) -> PayslipParser? {
        selectBestParserCallCount += 1
        lastText = text
        return parserToReturn
    }
}

/// Mock implementation of PayslipParser for testing
class MockPayslipParser: PayslipParser {
    // MARK: - Properties
    
    // Internal enum for confidence levels, used only within this class
    private enum MockConfidence {
        case low
        case medium
        case high
        
        func toParsingConfidence() -> ParsingConfidence {
            switch self {
            case .low: return ParsingConfidence.low
            case .medium: return ParsingConfidence.medium
            case .high: return ParsingConfidence.high
            }
        }
        
        static func from(_ confidence: String) -> MockConfidence {
            switch confidence.lowercased() {
            case "low": return .low
            case "medium": return .medium
            case "high", _: return .high
            }
        }
    }
    
    var name: String = "MockParser"
    var parsePayslipCallCount = 0
    var evaluateConfidenceCallCount = 0
    var lastDocument: PDFDocument?
    var lastPayslipItem: PayslipItem?
    var shouldSucceed = true
    var payslipToReturn: PayslipItem?
    private var mockConfidence: MockConfidence = .high
    
    // MARK: - Initialization
    
    // Public initializer that uses strings for confidence
    init(name: String = "MockParser", payslipToReturn: PayslipItem? = nil, shouldSucceed: Bool = true, confidence: String = "high") {
        self.name = name
        self.payslipToReturn = payslipToReturn
        self.shouldSucceed = shouldSucceed
        self.mockConfidence = MockConfidence.from(confidence)
        
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
    
    // Private initializer that uses the private enum
    private init(name: String = "MockParser", payslipToReturn: PayslipItem? = nil, shouldSucceed: Bool = true, mockConfidence: MockConfidence = .high) {
        self.name = name
        self.payslipToReturn = payslipToReturn
        self.shouldSucceed = shouldSucceed
        self.mockConfidence = mockConfidence
        
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
        parsePayslipCallCount = 0
        evaluateConfidenceCallCount = 0
        lastDocument = nil
        lastPayslipItem = nil
    }
    
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem? {
        parsePayslipCallCount += 1
        lastDocument = pdfDocument
        
        if shouldSucceed {
            return payslipToReturn
        } else {
            return nil
        }
    }
    
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence {
        evaluateConfidenceCallCount += 1
        lastPayslipItem = payslipItem
        return mockConfidence.toParsingConfidence()
    }
}

/// Mock implementation of the PayslipProcessingPipeline for testing
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
    var payslipToReturn: PayslipItem?
    
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
    
    func executePipeline(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
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

// MARK: - Mock Encryption Service
class MockEncryptionService: EncryptionServiceProtocol {
    // Flags to control behavior
    var shouldFailEncryption = false
    var shouldFailDecryption = false
    
    // Track method calls
    var encryptCallCount = 0
    var decryptCallCount = 0
    
    func reset() {
        shouldFailEncryption = false
        shouldFailDecryption = false
        encryptCallCount = 0
        decryptCallCount = 0
    }
    
    func encrypt(_ data: Data) throws -> Data {
        encryptCallCount += 1
        
        if shouldFailEncryption {
            throw EncryptionService.EncryptionError.encryptionFailed
        }
        
        // Simple simulation of encryption by encoding to base64
        return data.base64EncodedData()
    }
    
    func decrypt(_ data: Data) throws -> Data {
        decryptCallCount += 1
        
        if shouldFailDecryption {
            throw EncryptionService.EncryptionError.decryptionFailed
        }
        
        // Simple simulation of decryption by decoding from base64
        if let decodedData = Data(base64Encoded: data) {
            return decodedData
        } else {
            throw EncryptionService.EncryptionError.decryptionFailed
        }
    }
}

// MARK: - Mock Payslip Encryption Service
class MockPayslipEncryptionService: PayslipEncryptionServiceProtocol {
    // Flags to control behavior
    var shouldFailEncryption = false
    var shouldFailDecryption = false
    
    // Track method calls
    var encryptSensitiveDataCallCount = 0
    var decryptSensitiveDataCallCount = 0
    
    // Last parameters received
    var lastPayslip: AnyPayslip?
    
    func reset() {
        shouldFailEncryption = false
        shouldFailDecryption = false
        encryptSensitiveDataCallCount = 0
        decryptSensitiveDataCallCount = 0
        lastPayslip = nil
    }
    
    func encryptSensitiveData(in payslip: inout AnyPayslip) throws -> (nameEncrypted: Bool, accountNumberEncrypted: Bool, panNumberEncrypted: Bool) {
        encryptSensitiveDataCallCount += 1
        lastPayslip = payslip
        
        if shouldFailEncryption {
            throw MockError.encryptionFailed
        }
        
        // Simulate encryption by prefixing with "ENC:"
        if !payslip.name.hasPrefix("ENC:") {
            payslip.name = "ENC:" + payslip.name
        }
        
        if !payslip.accountNumber.hasPrefix("ENC:") {
            payslip.accountNumber = "ENC:" + payslip.accountNumber
        }
        
        if !payslip.panNumber.hasPrefix("ENC:") {
            payslip.panNumber = "ENC:" + payslip.panNumber
        }
        
        return (nameEncrypted: true, accountNumberEncrypted: true, panNumberEncrypted: true)
    }
    
    func decryptSensitiveData(in payslip: inout AnyPayslip) throws -> (nameDecrypted: Bool, accountNumberDecrypted: Bool, panNumberDecrypted: Bool) {
        decryptSensitiveDataCallCount += 1
        lastPayslip = payslip
        
        if shouldFailDecryption {
            throw MockError.decryptionFailed
        }
        
        // Simulate decryption by removing the "ENC:" prefix
        var nameDecrypted = false
        var accountNumberDecrypted = false
        var panNumberDecrypted = false
        
        if payslip.name.hasPrefix("ENC:") {
            payslip.name = String(payslip.name.dropFirst(4))
            nameDecrypted = true
        }
        
        if payslip.accountNumber.hasPrefix("ENC:") {
            payslip.accountNumber = String(payslip.accountNumber.dropFirst(4))
            accountNumberDecrypted = true
        }
        
        if payslip.panNumber.hasPrefix("ENC:") {
            payslip.panNumber = String(payslip.panNumber.dropFirst(4))
            panNumberDecrypted = true
        }
        
        return (nameDecrypted: nameDecrypted, accountNumberDecrypted: accountNumberDecrypted, panNumberDecrypted: panNumberDecrypted)
    }
}

// MARK: - Fallback Payslip Encryption Service
class FallbackPayslipEncryptionService: PayslipEncryptionServiceProtocol {
    private let error: Error
    
    init(error: Error) {
        self.error = error
    }
    
    func encryptSensitiveData(in payslip: inout AnyPayslip) throws -> (nameEncrypted: Bool, accountNumberEncrypted: Bool, panNumberEncrypted: Bool) {
        // Rethrow the original error
        throw error
    }
    
    func decryptSensitiveData(in payslip: inout AnyPayslip) throws -> (nameDecrypted: Bool, accountNumberDecrypted: Bool, panNumberDecrypted: Bool) {
        // Rethrow the original error
        throw error
    }
} 