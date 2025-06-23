import Foundation
import SwiftData
import PDFKit
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

// MARK: - Temporary MockError (will be fully extracted during refactoring)
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

// MARK: - Mock Error Types

// MARK: - Mock Security Service (Temporary - used by TestDIContainer)
class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = false
    var shouldAuthenticateSuccessfully = true
    var shouldFail = false
    var encryptionResult: Data?
    var decryptionResult: Data?
    var isBiometricAuthAvailable: Bool = true
    
    func reset() {
        isInitialized = false
        shouldAuthenticateSuccessfully = true
        shouldFail = false
        encryptionResult = nil
        decryptionResult = nil
        isBiometricAuthAvailable = true
    }
    
    func initialize() async throws {
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        if shouldFail {
            throw MockError.authenticationFailed
        }
        return shouldAuthenticateSuccessfully
    }
    
    func setupPIN(pin: String) async throws {
        if shouldFail {
            throw MockError.setupPINFailed
        }
    }
    
    func verifyPIN(pin: String) async throws -> Bool {
        if shouldFail {
            throw MockError.verifyPINFailed
        }
        return pin == "1234" // Simple mock implementation
    }
    
    func encryptData(_ data: Data) async throws -> Data {
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

// MARK: - Mock PDF Service
class MockPDFService: PDFServiceProtocol {
    var shouldFail = false
    var extractResult: [String: String] = [:]
    var unlockResult: Data?
    var isInitialized: Bool = false
    var mockValidationResult = PayslipContentValidationResult(
        isValid: true,
        confidence: 1.0,
        detectedFields: [],
        missingRequiredFields: []
    )
    
    func initialize() async throws {
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func process(_ url: URL) async throws -> Data {
        if shouldFail {
            throw MockError.processingFailed
        }
        return Data()
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
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
        if shouldFail {
            return [:]
        }
        return extractResult
    }
    
    func detectFormat(_ data: Data) -> PayslipFormat {
        return .pcda
    }
    
    func validateContent(_ data: Data) -> PayslipContentValidationResult {
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
class MockPDFExtractor: PDFExtractorProtocol {
    var shouldFail = false
    var mockPayslipItem: PayslipItem?
    var mockText = "This is mock extracted text"
    
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        if shouldFail {
            return nil
        }
        if let item = mockPayslipItem {
            return item
        }
        return PayslipItemFactory.createSample() as? PayslipItem
    }
    
    func extractPayslipData(from text: String) -> PayslipItem? {
        if shouldFail {
            return nil
        }
        if let item = mockPayslipItem {
            return item
        }
        return PayslipItemFactory.createSample() as? PayslipItem
    }
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        if shouldFail {
            return ""
        }
        return mockText
    }
    
    func getAvailableParsers() -> [String] {
        return ["MockParser1", "MockParser2"]
    }
    
    func reset() {
        shouldFail = false
        mockPayslipItem = nil
        mockText = "This is mock extracted text"
    }
}

// MARK: - Mock Payslip Format Detection Service
class MockPayslipFormatDetectionService: PayslipFormatDetectionServiceProtocol {
    var mockFormat: PayslipFormat = .standard
    
    func detectFormat(_ data: Data) -> PayslipFormat {
        return mockFormat
    }
    
    func detectFormat(fromText text: String) -> PayslipFormat {
        return mockFormat
    }
    
    func reset() {
        mockFormat = .standard
    }
}

// MARK: - Mock Text Extraction Service
class MockTextExtractionService: TextExtractionServiceProtocol {
    var mockText: String = "This is mock extracted text"
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        return mockText
    }
    
    func extractText(from page: PDFPage) -> String {
        return mockText
    }
    
    func extractDetailedText(from pdfDocument: PDFDocument) -> String {
        return mockText + "\n[DETAILED]"
    }
    
    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument) {
        // No-op for mock
    }
    
    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool {
        return !mockText.isEmpty
    }
    
    func reset() {
        mockText = "This is mock extracted text"
    }
}

/// Mock implementation of PayslipValidationServiceProtocol for testing

class MockPayslipValidationService: PayslipValidationServiceProtocol {
    var structureIsValid = true
    var contentIsValid = true
    var contentConfidence = 0.8
    var isPasswordProtected = false
    var payslipIsValid = true
    
    init(structureIsValid: Bool = true, contentIsValid: Bool = true, isPasswordProtected: Bool = false, payslipIsValid: Bool = true) {
        self.structureIsValid = structureIsValid
        self.contentIsValid = contentIsValid
        self.isPasswordProtected = isPasswordProtected
        self.payslipIsValid = payslipIsValid
    }
    
    func reset() {
        // No-op for simplified mock
    }
    
    func validatePDFStructure(_ data: Data) -> Bool {
        return structureIsValid
    }
    
    func validatePayslipContent(_ text: String) -> PayslipContentValidationResult {
        return PayslipContentValidationResult(
            isValid: contentIsValid,
            confidence: contentConfidence,
            detectedFields: contentIsValid ? ["name", "month", "year", "earnings", "deductions"] : [],
            missingRequiredFields: contentIsValid ? [] : ["name", "month", "year", "earnings", "deductions"]
        )
    }
    
    func isPDFPasswordProtected(_ data: Data) -> Bool {
        return isPasswordProtected
    }
    
    func validatePayslip(_ payslip: any PayslipProtocol) -> BasicPayslipValidationResult {
        return BasicPayslipValidationResult(
            isValid: payslipIsValid,
            errors: payslipIsValid ? [] : [.missingRequiredField("month"), .missingRequiredField("year")]
        )
    }
    
    func deepValidatePayslip(_ payslip: any PayslipProtocol) -> PayslipDeepValidationResult {
        
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



/// Mock implementation of PDFTextExtractionServiceProtocol for testing
class MockPDFTextExtractionService: PDFTextExtractionServiceProtocol {
    var shouldSucceed = true
    var textToReturn = "Mock PDF content for testing purposes"
    
    init(shouldSucceed: Bool = true, textToReturn: String? = nil) {
        self.shouldSucceed = shouldSucceed
        if let text = textToReturn {
            self.textToReturn = text
        }
    }
    
    func reset() {
        // No-op for simplified mock
    }
    
    func extractText(from data: Data) throws -> String {
        if !shouldSucceed {
            throw PDFProcessingError.textExtractionFailed
        }
        return textToReturn
    }
    
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
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
        if !shouldSucceed {
            return nil
        }
        return textToReturn
    }
    
    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
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
    var textToReturn = "Mock PDF text for testing purposes"
    var payslipToReturn: PayslipItem?
    var parserToReturn: PayslipParser?
    var shouldThrowError = false
    
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
    
    func reset() {
        shouldThrowError = false
    }
    
    func extractFullText(from document: PDFDocument) -> String? {
        return textToReturn
    }
    
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipItem? {
        if shouldThrowError {
            throw MockError.processingFailed
        }
        return payslipToReturn
    }
    
    func parsePayslip(pdfDocument: PDFDocument, using parserName: String) async throws -> PayslipItem? {
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
        return parserToReturn
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
    
    // Simplified mock without call tracking
    
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
        shouldValidateSuccessfully = true
        shouldExtractSuccessfully = true
        shouldDetectSuccessfully = true
        shouldProcessSuccessfully = true
    }
    
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

// MARK: - Mock Encryption Service

// MARK: - Mock Payslip Encryption Service (Temporary - used by TestDIContainer)
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

// MARK: - Fallback Payslip Encryption Service (Temporary - used by DIContainer)
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

// MARK: - Mock Encryption Service (Temporary - used by DIContainer)
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