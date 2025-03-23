//
//  MockServices.swift
//  Payslip Max
//
//  Created by Sunil on 26/02/25.
//

import Foundation
import SwiftData
import PDFKit

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
        // Simple mock implementation - just return the same data
        return data
    }
    
    func decryptData(_ data: Data) async throws -> Data {
        decryptCallCount += 1
        if shouldFail {
            throw MockError.decryptionFailed
        }
        if let result = decryptionResult {
            return result
        }
        // Simple mock implementation - just return the same data
        return data
    }
}

// MARK: - Mock Data Service
class MockDataService: DataServiceProtocol {
    var isInitialized: Bool = true
    var shouldFail = false
    
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
        if shouldFail {
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
}

// MARK: - Mock PDF Service
class MockPDFService: PDFServiceProtocol {
    var shouldFail = false
    var extractResult: [String: String] = [:]
    var unlockResult: Data?
    var isInitialized: Bool = true
    
    // Track method calls for verification in tests
    var extractCallCount = 0
    var unlockCallCount = 0
    var processCallCount = 0
    var initializeCallCount = 0
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
    }
    
    func process(_ url: URL) async throws -> Data {
        processCallCount += 1
        if shouldFail {
            throw MockError.unlockFailed
        }
        // Mock implementation - just return some test data
        return "Test PDF data".data(using: .utf8) ?? Data()
    }
    
    func extract(_ data: Data) -> [String: String] {
        extractCallCount += 1
        return extractResult.isEmpty ? ["page_1": "Mock PDF text"] : extractResult
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        unlockCallCount += 1
        if shouldFail {
            throw MockError.unlockFailed
        }
        return unlockResult ?? data
    }
}

// MARK: - Mock PDFExtractor
class MockPDFExtractor: PDFExtractorProtocol {
    var isInitialized: Bool = true
    var shouldFail = false
    var extractPayslipResult: PayslipItem?
    var extractTextResult: String = "Mock extracted text"
    var availableParsers: [String] = ["MockParser"]
    
    // Track method calls for verification in tests
    var extractPayslipCallCount = 0
    var extractTextCallCount = 0
    var getAvailableParsersCallCount = 0
    
    func initialize() async throws {
        if shouldFail {
            throw MockError.initializationFailed
        }
    }
    
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        extractPayslipCallCount += 1
        return extractPayslipResult ?? PayslipItem(
            month: "January",
            year: 2023,
            credits: 10000,
            debits: 2000,
            dsop: 500,
            tax: 1500,
            location: "Test",
            name: "Test User",
            accountNumber: "12345",
            panNumber: "ABCDE1234F",
            timestamp: Date()
        )
    }
    
    func extractPayslipData(from text: String) -> PayslipItem? {
        extractPayslipCallCount += 1
        return extractPayslipResult ?? PayslipItem(
            month: "January",
            year: 2023,
            credits: 10000,
            debits: 2000,
            dsop: 500,
            tax: 1500,
            location: "Test",
            name: "Test User",
            accountNumber: "12345",
            panNumber: "ABCDE1234F",
            timestamp: Date()
        )
    }
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        extractTextCallCount += 1
        return extractTextResult
    }
    
    func getAvailableParsers() -> [String] {
        getAvailableParsersCallCount += 1
        return availableParsers
    }
}

// MARK: - Mock PDF Processing Service
class MockPDFProcessingService: PDFProcessingServiceProtocol {
    var isInitialized: Bool = true
    var shouldFail: Bool = false
    var defaultFormat: PayslipFormat = .standard
    
    // Test data
    var mockPDFData: Data?
    var mockPayslipItem: PayslipItem?
    var mockValidationResult = ValidationResult(isValid: true, confidence: 1.0, detectedFields: ["name", "month", "year", "earnings", "deductions"], missingRequiredFields: [])
    
    // Call counts for verification in tests
    var initializeCallCount = 0
    var processPDFCallCount = 0
    var processPDFDataCallCount = 0
    var isPasswordProtectedCallCount = 0
    var unlockPDFCallCount = 0
    var processScannedImageCallCount = 0
    var detectFormatCallCount = 0
    var validateContentCallCount = 0
    
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
            return .failure(.fileAccessError("Mock error"))
        }
        return .success(mockPDFData ?? Data())
    }
    
    func processPDFData(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        processPDFDataCallCount += 1
        if shouldFail {
            return .failure(.parsingFailed("Mock error"))
        }
        if let item = mockPayslipItem {
            return .success(item)
        }
        // Create a default item if none provided
        let item = PayslipItem(
            month: "January",
            year: 2025,
            credits: 1000.0,
            debits: 200.0,
            dsop: 50.0,
            tax: 100.0,
            location: "Test Location",
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            timestamp: Date(),
            pdfData: data
        )
        return .success(item)
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
            return .failure(.conversionFailed)
        }
        if let item = mockPayslipItem {
            return .success(item)
        }
        // Create a default item if none provided
        let item = PayslipItem(
            month: "January",
            year: 2025,
            credits: 1000.0,
            debits: 200.0,
            dsop: 50.0,
            tax: 100.0,
            location: "Test Location",
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            timestamp: Date(),
            pdfData: nil
        )
        return .success(item)
    }
    
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        detectFormatCallCount += 1
        return defaultFormat
    }
    
    func validatePayslipContent(_ data: Data) -> ValidationResult {
        validateContentCallCount += 1
        return mockValidationResult
    }
}

// MARK: - Mock Error Types
enum MockError: LocalizedError {
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
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Mock initialization failed"
        case .encryptionFailed:
            return "Mock encryption failed"
        case .decryptionFailed:
            return "Mock decryption failed"
        case .authenticationFailed:
            return "Mock authentication failed"
        case .saveFailed:
            return "Mock save failed"
        case .fetchFailed:
            return "Mock fetch failed"
        case .deleteFailed:
            return "Mock delete failed"
        case .clearAllDataFailed:
            return "Mock clear all data failed"
        case .unlockFailed:
            return "Mock unlock failed"
        case .setupPINFailed:
            return "Mock setup PIN failed"
        case .verifyPINFailed:
            return "Mock verify PIN failed"
        }
    }
} 