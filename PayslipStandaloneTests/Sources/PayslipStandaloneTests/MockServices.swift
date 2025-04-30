import Foundation

// MARK: - Service Protocols
protocol ServiceProtocol {
    var isInitialized: Bool { get }
    func initialize() async throws
}

protocol SecurityServiceProtocol: ServiceProtocol {
    func encrypt(_ data: Data) async throws -> Data
    func decrypt(_ data: Data) async throws -> Data
    func authenticate() async throws -> Bool
}

protocol DataServiceProtocol: ServiceProtocol {
    func save<T: Identifiable>(_ item: T) async throws
    func saveBatch<T: Identifiable>(_ items: [T]) async throws
    func fetch<T: Identifiable>(_ type: T.Type) async throws -> [T]
    func fetchRefreshed<T: Identifiable>(_ type: T.Type) async throws -> [T]
    func delete<T: Identifiable>(_ item: T) async throws
    func deleteBatch<T: Identifiable>(_ items: [T]) async throws
    func clearAllData() async throws
}

protocol PDFServiceProtocol: ServiceProtocol {
    func process(_ url: URL) async throws -> Data
    func extract(_ data: Data) async throws -> StandalonePayslipItem
}

// MARK: - Mock Security Service
class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = false
    var shouldAuthenticateSuccessfully = true
    var shouldFail = false
    
    // Track method calls for verification in tests
    var initializeCount = 0
    var encryptCount = 0
    var decryptCount = 0
    var authenticateCount = 0
    
    func initialize() async throws {
        initializeCount += 1
        isInitialized = true
        if shouldFail {
            throw MockError.initializationFailed
        }
    }
    
    func encrypt(_ data: Data) async throws -> Data {
        encryptCount += 1
        if shouldFail {
            throw MockError.encryptionFailed
        }
        // Simple mock implementation - just return the same data
        return data
    }
    
    func decrypt(_ data: Data) async throws -> Data {
        decryptCount += 1
        if shouldFail {
            throw MockError.decryptionFailed
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
    var isInitialized: Bool = false
    var shouldFail = false
    
    // Storage for mock data
    var storedItems: [String: [Any]] = [:]
    
    // Track method calls for verification in tests
    var initializeCount = 0
    var saveCount = 0
    var fetchCount = 0
    var deleteCount = 0
    var clearAllDataCount = 0
    
    func initialize() async throws {
        initializeCount += 1
        isInitialized = true
        if shouldFail {
            throw MockError.initializationFailed
        }
    }
    
    func save<T>(_ item: T) async throws where T: Identifiable {
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
    
    func saveBatch<T>(_ entities: [T]) async throws where T: Identifiable {
        // Simple implementation for tests
        for entity in entities {
            try await save(entity)
        }
    }
    
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        fetchCount += 1
        if shouldFail {
            throw MockError.fetchFailed
        }
        let typeName = String(describing: T.self)
        return (storedItems[typeName] as? [T]) ?? []
    }
    
    func fetchRefreshed<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        // For tests, just call the regular fetch with an extra counter increment
        fetchCount += 1
        if shouldFail {
            throw MockError.fetchFailed
        }
        let typeName = String(describing: T.self)
        return (storedItems[typeName] as? [T]) ?? []
    }
    
    func delete<T>(_ item: T) async throws where T: Identifiable {
        deleteCount += 1
        if shouldFail {
            throw MockError.deleteFailed
        }
        // Simple implementation for tests
    }
    
    func deleteBatch<T>(_ entities: [T]) async throws where T: Identifiable {
        // Simple implementation for tests
        for entity in entities {
            try await delete(entity)
        }
    }
    
    func clearAllData() async throws {
        clearAllDataCount += 1
        if shouldFail {
            throw MockError.clearFailed
        }
        storedItems.removeAll()
    }
}

// MARK: - Mock PDF Service
class MockPDFService: PDFServiceProtocol {
    var isInitialized: Bool = false
    var shouldFail = false
    
    // Track method calls for verification in tests
    var initializeCount = 0
    var processCount = 0
    var extractCount = 0
    
    func initialize() async throws {
        initializeCount += 1
        isInitialized = true
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
    
    func extract(_ data: Data) async throws -> StandalonePayslipItem {
        extractCount += 1
        if shouldFail {
            throw MockError.extractionFailed
        }
        return StandalonePayslipItem.sample()
    }
}

// MARK: - Mock Errors
enum MockError: Error, Equatable {
    case initializationFailed
    case authenticationFailed
    case encryptionFailed
    case decryptionFailed
    case saveFailed
    case fetchFailed
    case deleteFailed
    case processingFailed
    case extractionFailed
    case clearFailed
} 