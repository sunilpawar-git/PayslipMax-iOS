import Foundation
import XCTest
import SwiftUI
import SwiftData
@testable import Payslip_Max

// MARK: - Mock Errors
enum MockSecurityError: Error {
    case initializationFailed
    case authenticationFailed
    case biometricsFailed
    case encryptionFailed
    case decryptionFailed
}

enum MockDataError: Error {
    case fetchFailed
    case saveFailed
    case deleteFailed
}

enum MockPDFError: Error {
    case processingFailed
    case extractionFailed
}

// MARK: - Mock Security Service
class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = false
    var shouldFail = false
    var initializeCount = 0
    var authenticateCount = 0
    var error: MockSecurityError?
    
    func initialize() async throws {
        initializeCount += 1
        if shouldFail {
            throw MockSecurityError.initializationFailed
        }
        isInitialized = true
    }
    
    func authenticate() async throws -> Bool {
        authenticateCount += 1
        if shouldFail {
            throw MockSecurityError.authenticationFailed
        }
        return true
    }
    
    func encrypt(_ data: Data) async throws -> Data {
        if shouldFail {
            throw MockSecurityError.encryptionFailed
        }
        var modifiedData = data
        if let firstByte = modifiedData.first {
            modifiedData[0] = firstByte ^ 0xFF
        } else if modifiedData.isEmpty {
            modifiedData.append(0xFF)
        }
        return modifiedData
    }
    
    func decrypt(_ data: Data) async throws -> Data {
        if shouldFail {
            throw MockSecurityError.decryptionFailed
        }
        var decryptedData = data
        if let firstByte = decryptedData.first {
            decryptedData[0] = firstByte ^ 0xFF
        }
        return decryptedData
    }
}

// MARK: - Mock Encryption Service
class MockEncryptionService: EncryptionServiceProtocol {
    var isInitialized = false
    var shouldFail = false
    var encryptionCount = 0
    var decryptionCount = 0
    var initializationCount = 0
    
    func encrypt(_ data: Data) throws -> Data {
        encryptionCount += 1
        if shouldFail {
            throw MockSecurityError.encryptionFailed
        }
        return data
    }
    
    func decrypt(_ data: Data) throws -> Data {
        decryptionCount += 1
        if shouldFail {
            throw MockSecurityError.decryptionFailed
        }
        return data
    }
    
    func initialize() async throws {
        initializationCount += 1
        if shouldFail {
            throw MockSecurityError.initializationFailed
        }
        isInitialized = true
    }
}

// MARK: - Mock Data Service Helper
class MockDataServiceHelper: DataServiceProtocol {
    var isInitialized: Bool = false
    var fetchCount = 0
    var saveCount = 0
    var deleteCount = 0
    var shouldFailFetch = false
    var shouldFailSave = false
    var shouldFailDelete = false
    var testPayslips: [PayslipItem] = []
    
    func initialize() async throws {
        if shouldFailFetch {
            throw MockDataError.fetchFailed
        }
        isInitialized = true
    }
    
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T] {
        fetchCount += 1
        if shouldFailFetch {
            throw MockDataError.fetchFailed
        }
        if type == PayslipItem.self {
            return testPayslips as! [T]
        }
        return []
    }
    
    func save<T: Codable>(_ item: T) async throws {
        saveCount += 1
        if shouldFailSave {
            throw MockDataError.saveFailed
        }
        if let payslipItem = item as? PayslipItem {
            if !testPayslips.contains(where: { $0.id == payslipItem.id }) {
                testPayslips.append(payslipItem)
            }
        }
    }
    
    func delete<T: Codable>(_ item: T) async throws {
        deleteCount += 1
        if shouldFailDelete {
            throw MockDataError.deleteFailed
        }
        if let payslipItem = item as? PayslipItem {
            testPayslips.removeAll(where: { $0.id == payslipItem.id })
        }
    }
}

// MARK: - Mock PDF Service
class MockPDFService: PDFServiceProtocol {
    var isInitialized = false
    var shouldFail = false
    var initializeCount = 0
    var processCount = 0
    var extractCount = 0
    
    // For testing
    var mockPayslipData: PayslipItem?
    private let pdfExtractor: PDFExtractorProtocol
    
    init(pdfExtractor: PDFExtractorProtocol? = nil) {
        self.pdfExtractor = pdfExtractor ?? MockPDFExtractor()
    }
    
    func initialize() async throws {
        initializeCount += 1
        if shouldFail {
            throw MockPDFError.initializationFailed
        }
        isInitialized = true
    }
    
    func process(_ url: URL) async throws -> Data {
        processCount += 1
        if shouldFail {
            throw MockPDFError.processingFailed
        }
        return Data()
    }
    
    func extract(_ data: Data) async throws -> Any {
        extractCount += 1
        if shouldFail {
            throw MockPDFError.extractionFailed
        }
        
        // Use the PDF extractor if available
        if let document = PDFDocument(data: data) {
            return try await pdfExtractor.extractPayslipData(from: document)
        }
        
        // Fallback to the mock data
        return mockPayslipData ?? PayslipItem(
            month: "January",
            year: 2025,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 500.0,
            tax: 800.0,
            location: "Test Location",
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
    }
}

// Protocol for ModelContext operations
// Removing duplicate protocol definition since it's already defined in the main app
// protocol ModelContextProtocol {
//     func insert<T: PersistentModel>(_ model: T)
//     func delete<T: PersistentModel>(_ model: T)
//     func save() throws
// }

// Make ModelContext conform to our protocol
// extension ModelContext: ModelContextProtocol {}

// Mock ModelContext for testing
class MockModelContext: ModelContextProtocol {
    var insertedObjects: [Any] = []
    var deletedObjects: [Any] = []
    var savedChanges = false
    
    func insert<T: PersistentModel>(_ model: T) {
        insertedObjects.append(model)
    }
    
    func delete<T: PersistentModel>(_ model: T) {
        deletedObjects.append(model)
    }
    
    func save() throws {
        savedChanges = true
    }
}

class MockDataService: DataServiceProtocol, ServiceProtocol {
    var isInitialized = false
    var mockItems: [String: [Any]] = [:]
    var shouldFailFetch = false
    var shouldFailSave = false
    var shouldFailDelete = false
    
    func initialize() async throws {
        // Implementation for initialize method
        isInitialized = true
    }
    
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T] {
        if shouldFailFetch {
            throw MockDataError.fetchFailed
        }
        
        let key = String(describing: type)
        return (mockItems[key] as? [T]) ?? []
    }
    
    func save<T: Codable>(_ item: T) async throws {
        if shouldFailSave {
            throw MockDataError.saveFailed
        }
        
        let key = String(describing: T.self)
        var items = mockItems[key] as? [T] ?? []
        items.append(item)
        mockItems[key] = items as [Any]
    }
    
    func delete<T: Codable>(_ item: T) async throws {
        if shouldFailDelete {
            throw MockDataError.deleteFailed
        }
        
        // In a real implementation, we would need to identify and remove the specific item
        // For simplicity in tests, we'll just clear all items of this type
        let key = String(describing: T.self)
        mockItems[key] = []
    }
} 