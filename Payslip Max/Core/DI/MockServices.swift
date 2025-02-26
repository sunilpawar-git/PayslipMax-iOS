//
//  MockServices.swift
//  Payslip Max
//
//  Created by Sunil on 26/02/25.
//

import Foundation

// MARK: - Mock Security Service
class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = true
    var shouldAuthenticateSuccessfully = true
    var encryptionResult: Data?
    var decryptionResult: Data?
    
    // Track method calls for verification in tests
    var initializeCallCount = 0
    var encryptCallCount = 0
    var decryptCallCount = 0
    var authenticateCallCount = 0
    
    func initialize() async throws {
        initializeCallCount += 1
    }
    
    func encrypt(_ data: Data) async throws -> Data {
        encryptCallCount += 1
        if let result = encryptionResult {
            return result
        }
        // Simple mock implementation - just return the same data
        return data
    }
    
    func decrypt(_ data: Data) async throws -> Data {
        decryptCallCount += 1
        if let result = decryptionResult {
            return result
        }
        // Simple mock implementation - just return the same data
        return data
    }
    
    func authenticate() async throws -> Bool {
        authenticateCallCount += 1
        return shouldAuthenticateSuccessfully
    }
}

// MARK: - Mock Data Service
class MockDataService: DataServiceProtocol {
    var isInitialized: Bool = true
    
    // Storage for mock data
    var storedItems: [String: [Any]] = [:]
    
    // Track method calls for verification in tests
    var initializeCallCount = 0
    var saveCallCount = 0
    var fetchCallCount = 0
    var deleteCallCount = 0
    
    func initialize() async throws {
        initializeCallCount += 1
    }
    
    func save<T: Codable>(_ item: T) async throws {
        saveCallCount += 1
        let typeName = String(describing: T.self)
        if storedItems[typeName] == nil {
            storedItems[typeName] = []
        }
        storedItems[typeName]?.append(item)
    }
    
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T] {
        fetchCallCount += 1
        let typeName = String(describing: T.self)
        return (storedItems[typeName] as? [T]) ?? []
    }
    
    func delete<T: Codable>(_ item: T) async throws {
        deleteCallCount += 1
        // In a real mock, you would implement proper deletion logic
    }
}

// MARK: - Mock PDF Service
class MockPDFService: PDFServiceProtocol {
    var isInitialized: Bool = true
    
    // Predefined results for testing
    var processResult: Data?
    var extractResult: PayslipItem?
    
    // Track method calls for verification in tests
    var initializeCallCount = 0
    var processCallCount = 0
    var extractCallCount = 0
    
    func initialize() async throws {
        initializeCallCount += 1
    }
    
    func process(_ url: URL) async throws -> Data {
        processCallCount += 1
        if let result = processResult {
            return result
        }
        return Data()
    }
    
    func extract(_ data: Data) async throws -> PayslipItem {
        extractCallCount += 1
        if let result = extractResult {
            return result
        }
        // Return a dummy payslip item
        return PayslipItem(
            month: "January",
            year: 2025,
            credits: 5000,
            debits: 1000,
            dsopf: 500,
            tax: 800,
            location: "Test Location",
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
    }
} 