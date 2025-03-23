import Foundation
import XCTest
import SwiftUI
import SwiftData
import PDFKit
@testable import Payslip_Max

// MARK: - Mock Errors
enum MockSecurityError: Error {
    case initializationFailed
    case authenticationFailed
    case biometricsFailed
    case encryptionFailed
    case decryptionFailed
    case pinSetupFailed
    case pinVerificationFailed
}

enum MockDataError: Error {
    case fetchFailed
    case saveFailed
    case deleteFailed
}

enum MockPDFError: Error {
    case initializationFailed
    case processingFailed
    case extractionFailed
    case parsingFailed
}

enum MockEncryptionError: Error {
    case encryptionFailed
    case decryptionFailed
}

// MARK: - Mock Security Service
class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = false
    var shouldFail = false
    var shouldAuthenticateSuccessfully = true
    var initializeCount = 0
    var authenticateCount = 0
    var isBiometricAuthAvailable: Bool = true
    var encryptCount = 0
    var decryptCount = 0
    var setupPINCount = 0
    var verifyPINCount = 0
    var error: MockSecurityError?
    
    func initialize() async throws {
        initializeCount += 1
        if shouldFail {
            throw MockSecurityError.initializationFailed
        }
        isInitialized = true
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        authenticateCount += 1
        if shouldFail {
            throw MockSecurityError.authenticationFailed
        }
        return shouldAuthenticateSuccessfully
    }
    
    func setupPIN(pin: String) async throws {
        setupPINCount += 1
        if shouldFail {
            throw MockSecurityError.pinSetupFailed
        }
    }
    
    func verifyPIN(pin: String) async throws -> Bool {
        verifyPINCount += 1
        if shouldFail {
            throw MockSecurityError.pinVerificationFailed
        }
        return true
    }
    
    func encryptData(_ data: Data) async throws -> Data {
        encryptCount += 1
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
    
    func decryptData(_ data: Data) async throws -> Data {
        decryptCount += 1
        if shouldFail {
            throw MockSecurityError.decryptionFailed
        }
        var decryptedData = data
        if let firstByte = decryptedData.first {
            decryptedData[0] = firstByte ^ 0xFF
        }
        return decryptedData
    }
    
    // Legacy methods for backward compatibility
    func authenticate() async throws -> Bool {
        return try await authenticateWithBiometrics()
    }
    
    func encrypt(_ data: Data) async throws -> Data {
        return try await encryptData(data)
    }
    
    func decrypt(_ data: Data) async throws -> Data {
        return try await decryptData(data)
    }
}

// MARK: - Mock Encryption Service
class MockEncryptionService: EncryptionServiceProtocol {
    var encryptionCount = 0
    var decryptionCount = 0
    var shouldFailEncryption = false
    var shouldFailDecryption = false
    
    // For backward compatibility with tests that use shouldFail
    var shouldFail: Bool {
        get {
            return shouldFailEncryption && shouldFailDecryption
        }
        set {
            shouldFailEncryption = newValue
            shouldFailDecryption = newValue
        }
    }
    
    func encrypt(_ data: Data) throws -> Data {
        encryptionCount += 1
        if shouldFailEncryption {
            throw MockEncryptionError.encryptionFailed
        }
        return data
    }
    
    func decrypt(_ data: Data) throws -> Data {
        decryptionCount += 1
        if shouldFailDecryption {
            throw MockEncryptionError.decryptionFailed
        }
        return data
    }
}

// MARK: - Mock Data Service Helper
class MockDataServiceHelper: DataServiceProtocol {
    var isInitialized: Bool = false
    var fetchCount = 0
    var saveCount = 0
    var deleteCount = 0
    var clearAllDataCount = 0
    var shouldFailFetch = false
    var shouldFailSave = false
    var shouldFailDelete = false
    var shouldFailClearAllData = false
    var testPayslips: [PayslipItem] = []
    
    func initialize() async throws {
        if shouldFailFetch {
            throw MockDataError.fetchFailed
        }
        isInitialized = true
    }
    
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        fetchCount += 1
        if shouldFailFetch {
            throw MockDataError.fetchFailed
        }
        if type == PayslipItem.self {
            return testPayslips as! [T]
        }
        return []
    }
    
    func save<T>(_ item: T) async throws where T: Identifiable {
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
    
    func delete<T>(_ item: T) async throws where T: Identifiable {
        deleteCount += 1
        if shouldFailDelete {
            throw MockDataError.deleteFailed
        }
        if let payslipItem = item as? PayslipItem {
            testPayslips.removeAll(where: { $0.id == payslipItem.id })
        }
    }
    
    func clearAllData() async throws {
        clearAllDataCount += 1
        if shouldFailClearAllData {
            throw MockDataError.deleteFailed
        }
        testPayslips.removeAll()
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
    private var modelContext: ModelContext
    var insertedObjects: [Any] = []
    var deletedObjects: [Any] = []
    var savedChanges = false
    
    init(_ container: ModelContainer) {
        self.modelContext = ModelContext(container)
    }
    
    func insert<T: PersistentModel>(_ model: T) {
        insertedObjects.append(model)
        modelContext.insert(model)
    }
    
    func delete<T: PersistentModel>(_ model: T) {
        deletedObjects.append(model)
        modelContext.delete(model)
    }
    
    func save() throws {
        savedChanges = true
        try modelContext.save()
    }
}

// MARK: - Mock Data Service
class MockDataService: DataServiceProtocol {
    var isInitialized: Bool = true
    var shouldFail = false
    var shouldFailFetch = false
    var shouldFailSave = false
    var shouldFailDelete = false
    var shouldFailClearAllData = false
    
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
            throw MockDataError.fetchFailed
        }
    }
    
    func save<T>(_ item: T) async throws where T: Identifiable {
        saveCallCount += 1
        if shouldFail || shouldFailSave {
            throw MockDataError.saveFailed
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
            throw MockDataError.fetchFailed
        }
        let typeName = String(describing: T.self)
        if let items = storedItems[typeName] as? [T] {
            return items
        }
        return []
    }
    
    func delete<T>(_ item: T) async throws where T: Identifiable {
        deleteCallCount += 1
        if shouldFail || shouldFailDelete {
            throw MockDataError.deleteFailed
        }
        // In a real implementation, we would identify and remove the item
        // For simplicity in tests, we'll just simulate the deletion
    }
    
    func clearAllData() async throws {
        clearAllDataCallCount += 1
        if shouldFail || shouldFailClearAllData {
            throw MockDataError.deleteFailed
        }
        storedItems.removeAll()
    }
}

// MARK: - PayslipItem Extension for Testing
extension PayslipItem {
    static var encryptionServiceFactory: (() -> Any)?
    
    static func setEncryptionServiceFactory(_ factory: @escaping () -> Any) -> Any {
        encryptionServiceFactory = factory
        return factory()
    }
    
    static func resetEncryptionServiceFactory() {
        encryptionServiceFactory = nil
    }
    
    func decryptSensitiveData() throws {
        // If we have a mock encryption service, increment its decryption count
        if let factory = PayslipItem.encryptionServiceFactory,
           let mockService = factory() as? MockEncryptionService {
            mockService.decryptionCount += 1
        }
        
        // No actual decryption needed for tests
    }
    
    func encryptSensitiveData() throws {
        // No actual encryption needed for tests
    }
} 