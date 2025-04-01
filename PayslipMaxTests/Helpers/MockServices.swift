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
    case pinSetupFailed
    case pinVerificationFailed
    case encryptionFailed
    case decryptionFailed
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

// MARK: - Mock Security Service
@MainActor
class MockSecurityService: SecurityServiceProtocol {
    var isInitialized = false
    var shouldFail = false
    var initializeCount = 0
    var authenticateCount = 0
    var setupPINCount = 0
    var verifyPINCount = 0
    var encryptCount = 0
    var decryptCount = 0
    var isBiometricAuthAvailable = true
    
    func initialize() async throws {
        initializeCount += 1
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
        return true
    }
    
    func setupPIN(pin: String) async throws {
        setupPINCount += 1
        if shouldFail {
            throw MockError.setupPINFailed
        }
    }
    
    func verifyPIN(pin: String) async throws -> Bool {
        verifyPINCount += 1
        if shouldFail {
            throw MockError.verifyPINFailed
        }
        return true
    }
    
    func encryptData(_ data: Data) async throws -> Data {
        encryptCount += 1
        if shouldFail {
            throw MockError.encryptionFailed
        }
        return data
    }
    
    func decryptData(_ data: Data) async throws -> Data {
        decryptCount += 1
        if shouldFail {
            throw MockError.decryptionFailed
        }
        return data
    }
}

// MARK: - Mock Data Service
@MainActor
class MockDataServiceHelper: DataServiceProtocol {
    var isInitialized = false
    var shouldFailSave = false
    var shouldFailFetch = false
    var shouldFailDelete = false
    var shouldFailInit = false
    var items: [any Identifiable] = []
    
    func initialize() async throws {
        if shouldFailInit {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func save<T>(_ entity: T) async throws where T: Identifiable {
        if shouldFailSave {
            throw MockError.saveFailed
        }
        
        // If it's a PayslipItem, we need to handle it specially
        if let payslipItem = entity as? PayslipItem {
            // Remove existing item with same ID if it exists
            items.removeAll { ($0 as? PayslipItem)?.id == payslipItem.id }
            items.append(payslipItem)
        } else {
            // For other Identifiable types
            items.removeAll { ($0.id as? T.ID) == entity.id }
            items.append(entity)
        }
    }
    
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        if shouldFailFetch {
            throw MockError.fetchFailed
        }
        
        return items.compactMap { $0 as? T }
    }
    
    func delete<T>(_ entity: T) async throws where T: Identifiable {
        if shouldFailDelete {
            throw MockError.deleteFailed
        }
        
        if let payslipItem = entity as? PayslipItem {
            items.removeAll { ($0 as? PayslipItem)?.id == payslipItem.id }
        } else {
            items.removeAll { ($0.id as? T.ID) == entity.id }
        }
    }
    
    func clearAllData() async throws {
        items.removeAll()
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
    
    func reset() {
        isInitialized = true
        shouldFail = false
        shouldFailFetch = false
        shouldFailSave = false
        shouldFailDelete = false
        shouldFailClearAllData = false
        storedItems.removeAll()
        initializeCallCount = 0
        saveCallCount = 0
        fetchCallCount = 0
        deleteCallCount = 0
        clearAllDataCallCount = 0
    }
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockDataError.fetchFailed
        }
    }
    
    func save<T>(_ item: T) async throws where T: Identifiable {
        if shouldFailSave {
            throw MockError.saveFailed
        }
        
        print("DEBUG: Attempting to save item of type \(type(of: item))")
        
        if let item = item as? any PayslipItemProtocol {
            let key = String(describing: PayslipItem.self)
            if var items = storedItems[key] {
                items.append(item)
                storedItems[key] = items
                print("DEBUG: Stored item in existing array for key \(key)")
            } else {
                storedItems[key] = [item]
                print("DEBUG: Created new array for key \(key)")
            }
        } else {
            let key = String(describing: type(of: item))
            if var items = storedItems[key] {
                items.append(item)
                storedItems[key] = items
                print("DEBUG: Stored item in existing array for key \(key)")
            } else {
                storedItems[key] = [item]
                print("DEBUG: Created new array for key \(key)")
            }
        }
    }
    
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        if shouldFailFetch {
            throw MockError.fetchFailed
        }
        
        print("DEBUG: Attempting to fetch items of type \(type)")
        
        if T.self == PayslipItem.self {
            // First check for exact PayslipItem matches
            if let items = storedItems[String(describing: PayslipItem.self)] as? [T] {
                print("DEBUG: Found \(items.count) PayslipItem(s)")
                return items
            }
            
            // Then check for items conforming to PayslipItemProtocol
            var conformingItems: [T] = []
            for (_, items) in storedItems {
                if let protocolItems = items as? [any PayslipItemProtocol] {
                    for item in protocolItems {
                        if let payslipItem = PayslipItem(
                            id: item.id,
                            month: item.month,
                            year: item.year,
                            credits: item.credits,
                            debits: item.debits,
                            dsop: item.dsop,
                            tax: item.tax,
                            name: item.name,
                            accountNumber: item.accountNumber,
                            panNumber: item.panNumber,
                            timestamp: item.timestamp
                        ) as? T {
                            if let protocolItem = item as? any PayslipItemProtocol {
                                (payslipItem as? PayslipItem)?.earnings = protocolItem.earnings
                                (payslipItem as? PayslipItem)?.deductions = protocolItem.deductions
                            }
                            conformingItems.append(payslipItem)
                        }
                    }
                }
            }
            print("DEBUG: Found \(conformingItems.count) items conforming to PayslipItemProtocol")
            return conformingItems
        }
        
        // For other types, just return the stored items directly
        if let items = storedItems[String(describing: type)] as? [T] {
            print("DEBUG: Found \(items.count) items of type \(type)")
            return items
        }
        
        print("DEBUG: No items found for type \(type)")
        return []
    }
    
    func delete<T>(_ item: T) async throws where T: Identifiable {
        deleteCallCount += 1
        
        if shouldFailDelete {
            throw MockError.deleteFailed
        }
        
        print("DEBUG: Attempting to delete item of type \(type(of: item))")
        
        if let item = item as? any PayslipItemProtocol {
            let key = String(describing: PayslipItem.self)
            if var items = storedItems[key] {
                items.removeAll { storedItem in
                    if let identifiableItem = storedItem as? any Identifiable {
                        return identifiableItem.id as? AnyHashable == (item as? any Identifiable)?.id as? AnyHashable
                    }
                    return false
                }
                storedItems[key] = items
                print("DEBUG: Removed item from array for key \(key)")
            }
        } else {
            let key = String(describing: type(of: item))
            if var items = storedItems[key] {
                items.removeAll { storedItem in
                    if let identifiableItem = storedItem as? any Identifiable {
                        return identifiableItem.id as? AnyHashable == (item as? any Identifiable)?.id as? AnyHashable
                    }
                    return false
                }
                storedItems[key] = items
                print("DEBUG: Removed item from array for key \(key)")
            }
        }
    }
    
    func clearAllData() async throws {
        clearAllDataCallCount += 1
        if shouldFail || shouldFailClearAllData {
            throw MockDataError.deleteFailed
        }
        storedItems.removeAll()
    }
} 