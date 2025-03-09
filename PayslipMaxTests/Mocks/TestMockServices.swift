import Foundation

// Define the protocol locally to avoid import issues
protocol EncryptionServiceProtocolInternal {
    func encrypt(_ data: Data) throws -> Data
    func decrypt(_ data: Data) throws -> Data
}

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

// Mock implementation of EncryptionServiceProtocolInternal for testing PayslipItem
class MockEncryptionService: EncryptionServiceProtocolInternal {
    var shouldFail = false
    var encryptionCount = 0
    var decryptionCount = 0
    
    func encrypt(_ data: Data) throws -> Data {
        encryptionCount += 1
        if shouldFail {
            throw MockError.encryptionFailed
        }
        // For testing, we'll just return the base64 encoded data
        return data.base64EncodedData()
    }
    
    func decrypt(_ data: Data) throws -> Data {
        decryptionCount += 1
        if shouldFail {
            throw MockError.decryptionFailed
        }
        // For testing, we'll assume the data is base64 encoded
        if let decodedData = Data(base64Encoded: data) {
            return decodedData
        }
        // If it's not base64 encoded, just return the original data
        return data
    }
}

class MockDataService {
    var isInitialized: Bool = true
    var shouldFail = false
    
    // Track method calls for verification in tests
    var initializeCount = 0
    var saveCount = 0
    var fetchCount = 0
    var deleteCount = 0
    
    // Storage for mock data
    private var storage: [String: [Any]] = [:]
    
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
        if storage[typeName] == nil {
            storage[typeName] = []
        }
        storage[typeName]?.append(item)
    }
    
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T] {
        fetchCount += 1
        if shouldFail {
            throw MockError.fetchFailed
        }
        
        let typeName = String(describing: T.self)
        return (storage[typeName] as? [T]) ?? []
    }
    
    func delete<T: Codable>(_ item: T) async throws {
        deleteCount += 1
        if shouldFail {
            throw MockError.deleteFailed
        }
        
        // In a real implementation, we would remove the item from storage
        // For simplicity in tests, we'll just increment the counter
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
        // Return some dummy data for testing
        return "Test PDF Content".data(using: .utf8)!
    }
    
    func extract(_ data: Data) async throws -> MockPayslipItem {
        extractCount += 1
        if shouldFail {
            throw MockError.extractionFailed
        }
        // Return a sample payslip item for testing
        return MockPayslipItem.sample()
    }
}

// Simple mock payslip item for testing
struct MockPayslipItem: Identifiable, Codable {
    var id: UUID
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dspof: Double
    var tax: Double
    var location: String
    var name: String
    var accountNumber: String
    var panNumber: String
    
    static func sample() -> MockPayslipItem {
        return MockPayslipItem(
            id: UUID(),
            month: "January",
            year: 2025,
            credits: 5000.0,
            debits: 1000.0,
            dspof: 500.0,
            tax: 800.0,
            location: "Test Location",
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
    }
}

// Common error types for mock services
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