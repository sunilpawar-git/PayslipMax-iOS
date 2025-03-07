import Foundation
import XCTest
@testable import Payslip_Max

// Test-specific mock services that don't rely on the main app's protocols
class MockSecurityService {
    var isInitialized: Bool = true
    var shouldAuthenticateSuccessfully = true
    var shouldFail = false
    
    // Track method calls for verification in tests
    var initializeCount = 0
    var encryptCount = 0
    var decryptCount = 0
    var authenticateCount = 0
    
    func initialize() async throws {
        initializeCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
    }
    
    func encrypt(_ data: Data) async throws -> Data {
        encryptCount += 1
        if shouldFail {
            throw MockError.encryptionFailed
        }
        return data
    }
    
    func decrypt(_ data: Data) async throws -> Data {
        decryptCount += 1
        if shouldFail {
            throw MockError.decryptionFailed
        }
        return data
    }
    
    func authenticate() async throws -> Bool {
        authenticateCount += 1
        if shouldFail {
            throw MockError.authenticationFailed
        }
        return shouldAuthenticateSuccessfully
    }
}

class MockDataService {
    var isInitialized: Bool = true
    var shouldFail = false
    
    // Storage for mock data
    var storedItems: [String: [Any]] = [:]
    
    // Track method calls for verification in tests
    var initializeCount = 0
    var saveCount = 0
    var fetchCount = 0
    var deleteCount = 0
    
    func initialize() async throws {
        initializeCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
    }
    
    func save<T: Codable>(_ item: T) async throws {
        saveCount += 1
        if shouldFail {
            throw MockError.saveFailed
        }
        let typeName = String(describing: T.self)
        if storedItems[typeName] == nil {
            storedItems[typeName] = []
        }
        storedItems[typeName]?.append(item)
    }
    
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T] {
        fetchCount += 1
        if shouldFail {
            throw MockError.fetchFailed
        }
        let typeName = String(describing: T.self)
        return (storedItems[typeName] as? [T]) ?? []
    }
    
    func delete<T: Codable>(_ item: T) async throws {
        deleteCount += 1
        if shouldFail {
            throw MockError.deleteFailed
        }
    }
}

class MockPDFService {
    var isInitialized: Bool = true
    var shouldFail = false
    
    // Track method calls for verification in tests
    var initializeCount = 0
    var processCount = 0
    var extractCount = 0
    
    func initialize() async throws {
        initializeCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
    }
    
    func process(_ url: URL) async throws -> Data {
        processCount += 1
        if shouldFail {
            throw MockError.processingFailed
        }
        return Data()
    }
    
    func extract(_ data: Data) async throws -> TestPayslipItem {
        extractCount += 1
        if shouldFail {
            throw MockError.extractionFailed
        }
        return TestPayslipItem.sample()
    }
}

// MARK: - Mock Errors
enum MockError: Error {
    case initializationFailed
    case authenticationFailed
    case encryptionFailed
    case decryptionFailed
    case saveFailed
    case fetchFailed
    case deleteFailed
    case processingFailed
    case extractionFailed
} 