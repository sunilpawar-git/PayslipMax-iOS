import Foundation
import SwiftData
import PDFKit

// MARK: - Mock Error Types
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
class MockDataService: DataServiceProtocol {
    var isInitialized: Bool = false
    var shouldFail = false
    var shouldFailFetch = false
    
    // Storage for mock data
    var storedItems: [String: [Any]] = [:]
    
    // Track method calls for verification in tests
    var initializeCallCount = 0
    var saveCallCount = 0
    var fetchCallCount = 0
    var deleteCallCount = 0
    var clearAllDataCallCount = 0
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func save<T>(_ item: T) async throws where T: Identifiable {
        saveCallCount += 1
        if shouldFail {
            throw MockError.saveFailed
        }
        let typeName = String(describing: T.self)
        if storedItems[typeName] == nil {
            storedItems[typeName] = []
        }
        storedItems[typeName]?.append(item)
    }
    
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        fetchCallCount += 1
        if shouldFail || shouldFailFetch {
            throw MockError.fetchFailed
        }
        let typeName = String(describing: T.self)
        if let items = storedItems[typeName] as? [T] {
            return items
        }
        return []
    }
    
    func delete<T>(_ item: T) async throws where T: Identifiable {
        deleteCallCount += 1
        if shouldFail {
            throw MockError.deleteFailed
        }
        let typeName = String(describing: T.self)
        if var items = storedItems[typeName] {
            // Create a safer comparison mechanism using UUID or string description
            if let idItem = item as? PayslipItem {
                items.removeAll { 
                    if let currentItem = $0 as? PayslipItem {
                        return currentItem.id == idItem.id
                    }
                    return false
                }
            } else {
                // Fallback to string description for non-PayslipItem types
                let itemString = String(describing: item)
                items.removeAll { String(describing: $0) == itemString }
            }
            storedItems[typeName] = items
        }
    }
    
    func clearAllData() async throws {
        clearAllDataCallCount += 1
        if shouldFail {
            throw MockError.clearAllDataFailed
        }
        storedItems.removeAll()
    }
    
    func reset() {
        isInitialized = false
        shouldFail = false
        shouldFailFetch = false
        storedItems.removeAll()
        initializeCallCount = 0
        saveCallCount = 0
        fetchCallCount = 0
        deleteCallCount = 0
        clearAllDataCallCount = 0
    }
}

// MARK: - Mock PDF Service
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
    var mockValidationResult = ValidationResult(
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
    
    func validateContent(_ data: Data) -> ValidationResult {
        validateContentCallCount += 1
        if shouldFail {
            return ValidationResult(
                isValid: false,
                confidence: 0.0,
                detectedFields: [],
                missingRequiredFields: ["Mock validation failed"]
            )
        }
        return mockValidationResult
    }
    
    func validatePayslipData(_ data: [String: String]) -> ValidationResult {
        validationCallCount += 1
        if shouldFail {
            return ValidationResult(
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
        mockValidationResult = ValidationResult(
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
    
    func validatePayslipContent(_ data: Data) -> ValidationResult {
        validatePayslipContentCallCount += 1
        if shouldFail {
            return ValidationResult(
                isValid: false,
                confidence: 0.0,
                detectedFields: [],
                missingRequiredFields: ["Mock validation failed"]
            )
        }
        return ValidationResult(
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