//
//  MockServices.swift
//  Payslip Max
//
//  Created by Sunil on 26/02/25.
//

import Foundation

// MARK: - Mock Security Service
class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = false
    var shouldAuthenticateSuccessfully = true
    var shouldFail = false
    var encryptionResult: Data?
    var decryptionResult: Data?
    
    // Track method calls for verification in tests
    var initializeCallCount = 0
    var encryptCallCount = 0
    var decryptCallCount = 0
    var authenticateCount = 0
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func encrypt(_ data: Data) async throws -> Data {
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
    
    func decrypt(_ data: Data) async throws -> Data {
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
    
    func authenticate() async throws -> Bool {
        authenticateCount += 1
        if shouldFail {
            throw MockError.authenticationFailed
        }
        return shouldAuthenticateSuccessfully
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
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
    }
    
    func save<T: Codable>(_ item: T) async throws {
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
    
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T] {
        fetchCallCount += 1
        if shouldFail {
            throw MockError.fetchFailed
        }
        let typeName = String(describing: T.self)
        return (storedItems[typeName] as? [T]) ?? []
    }
    
    func delete<T: Codable>(_ item: T) async throws {
        deleteCallCount += 1
        if shouldFail {
            throw MockError.deleteFailed
        }
        // In a real mock, you would implement proper deletion logic
    }
}

// MARK: - Mock PDF Service
class MockPDFService: PDFServiceProtocol {
    var isInitialized: Bool = true
    var shouldFail = false
    
    // Predefined results for testing
    var processResult: Data?
    var extractResult: Any?
    
    // Track method calls for verification in tests
    var initializeCallCount = 0
    var processCallCount = 0
    var extractCallCount = 0
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
    }
    
    func process(_ url: URL) async throws -> Data {
        processCallCount += 1
        if shouldFail {
            throw MockError.processingFailed
        }
        if let result = processResult {
            return result
        }
        return Data()
    }
    
    func extract(_ data: Data) async throws -> Any {
        extractCallCount += 1
        if shouldFail {
            throw MockError.extractionFailed
        }
        if let result = extractResult {
            return result
        }
        // Return a dummy payslip item
        return ["month": "1", "year": 2025, "credits": 5000.0] as [String: Any]
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