import Foundation
@testable import PayslipMax
import SwiftData

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
    
    func fetchRefreshed<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        // For mock purposes, just call the regular fetch method but increment a counter
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
    
    // MARK: - Batch Operations
    
    func saveBatch<T>(_ entities: [T]) async throws where T: Identifiable {
        saveCallCount += entities.count
        if shouldFail {
            throw MockError.saveFailed
        }
        
        for entity in entities {
            let typeName = String(describing: T.self)
            if storedItems[typeName] == nil {
                storedItems[typeName] = []
            }
            storedItems[typeName]?.append(entity)
        }
    }
    
    func deleteBatch<T>(_ entities: [T]) async throws where T: Identifiable {
        deleteCallCount += entities.count
        if shouldFail {
            throw MockError.deleteFailed
        }
        
        for entity in entities {
            let typeName = String(describing: T.self)
            if var items = storedItems[typeName] {
                // Create a safer comparison mechanism using UUID or string description
                if let idItem = entity as? PayslipItem {
                    items.removeAll { 
                        if let currentItem = $0 as? PayslipItem {
                            return currentItem.id == idItem.id
                        }
                        return false
                    }
                } else {
                    // Fallback to string description for non-PayslipItem types
                    let itemString = String(describing: entity)
                    items.removeAll { String(describing: $0) == itemString }
                }
                storedItems[typeName] = items
            }
        }
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