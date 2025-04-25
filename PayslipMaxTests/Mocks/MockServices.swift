import Foundation
@testable import Payslip_Max

/*
// MARK: - Mock Encryption Service
// COMMENTED OUT: This class has been moved to PayslipMaxTests/Mocks/Security/MockEncryptionService.swift
class MockEncryptionService: SensitiveDataEncryptionService {
    var encryptionCount = 0
    var decryptionCount = 0
    var shouldFailEncryption = false
    var shouldFailDecryption = false
    var shouldFailKeyManagement = false
    
    func encrypt(_ data: Data) throws -> Data {
        encryptionCount += 1
        if shouldFailEncryption {
            throw EncryptionService.EncryptionError.encryptionFailed
        }
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
        return data.base64EncodedData()
    }
    
    func decrypt(_ data: Data) throws -> Data {
        decryptionCount += 1
        if shouldFailDecryption {
            throw EncryptionService.EncryptionError.decryptionFailed
        }
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
        return Data(base64Encoded: data) ?? data
    }
    
    func reset() {
        shouldFailEncryption = false
        shouldFailDecryption = false
        shouldFailKeyManagement = false
        encryptionCount = 0
        decryptionCount = 0
    }
}
*/

/* 
// MARK: - Mock Data Service
// COMMENTED OUT: This class has been moved to PayslipMaxTests/Mocks/Core/MockDataService.swift
@MainActor class MockDataService: DataServiceProtocol {
    var isInitialized: Bool = false
    var shouldFail = false
    var shouldFailFetch = false
    var initializeCallCount = 0
    var fetchCallCount = 0
    var saveCount = 0
    var deleteCount = 0
    var clearCallCount = 0
    private var storedData: [String: [any Identifiable]] = [:]
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        fetchCallCount += 1
        if shouldFailFetch {
            throw MockError.fetchFailed
        }
        let key = String(describing: type)
        return (storedData[key] as? [T]) ?? []
    }
    
    func save<T>(_ entity: T) async throws where T: Identifiable {
        saveCount += 1
        if shouldFail {
            throw MockError.saveFailed
        }
        let key = String(describing: T.self)
        var entities = storedData[key] ?? []
        entities.append(entity)
        storedData[key] = entities
    }
    
    func delete<T>(_ entity: T) async throws where T: Identifiable {
        deleteCount += 1
        if shouldFail {
            throw MockError.deleteFailed
        }
        let key = String(describing: T.self)
        if var entities = storedData[key] {
            entities.removeAll { ($0 as? T)?.id == entity.id }
            storedData[key] = entities
        }
    }
    
    func clearAllData() async throws {
        clearCallCount += 1
        if shouldFail {
            throw MockError.clearAllDataFailed
        }
        storedData.removeAll()
    }
    
    func reset() {
        isInitialized = false
        shouldFail = false
        shouldFailFetch = false
        initializeCallCount = 0
        fetchCallCount = 0
        saveCount = 0
        deleteCount = 0
        clearCallCount = 0
        storedData.removeAll()
    }
}
*/

/*
// MARK: - Mock PDF Service
// COMMENTED OUT: This class has been moved to PayslipMaxTests/Mocks/PDF/MockPDFService.swift
@MainActor class MockPDFService: PDFServiceProtocol {
    var isInitialized = false
    var initializeCallCount = 0
    var processCallCount = 0
    var unlockCallCount = 0
    var extractCallCount = 0
    var extractResult: [String: String] = [:]
    var shouldFail = false
    var mockPDFData = Data()
    var unlockResult = Data()
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func process(_ url: URL) async throws -> Data {
        processCallCount += 1
        if shouldFail {
            throw MockError.processingFailed
        }
        return mockPDFData
    }
    
    func extract(_ data: Data) -> [String: String] {
        extractCallCount += 1
        return extractResult
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        unlockCallCount += 1
        if shouldFail {
            throw MockError.unlockFailed
        }
        return unlockResult
    }
    
    func reset() {
        isInitialized = false
        initializeCallCount = 0
        processCallCount = 0
        unlockCallCount = 0
        extractCallCount = 0
        extractResult = [:]
        shouldFail = false
        mockPDFData = Data()
        unlockResult = Data()
    }
}
*/

/*
// MARK: - Mock Data Service Helper
// COMMENTED OUT: This class has been moved to PayslipMaxTests/Mocks/Core/MockDataServiceHelper.swift
@MainActor class MockDataServiceHelper: DataServiceProtocol {
    var isInitialized = false
    var initializeCallCount = 0
    var fetchCallCount = 0
    var saveCount = 0
    var deleteCount = 0
    var clearCallCount = 0
    var shouldFailSave = false
    var shouldFailFetch = false
    var shouldFailDelete = false
    var shouldFailClear = false
    var testPayslips: [PayslipItem] = []
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFailSave {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        fetchCallCount += 1
        if shouldFailFetch {
            throw MockError.fetchFailed
        }
        if type is PayslipItem.Type {
            return testPayslips as! [T]
        }
        return []
    }
    
    func save<T>(_ entity: T) async throws where T: Identifiable {
        saveCount += 1
        if shouldFailSave {
            throw MockError.saveFailed
        }
        if let payslip = entity as? PayslipItem {
            testPayslips.append(payslip)
        }
    }
    
    func delete<T>(_ entity: T) async throws where T: Identifiable {
        deleteCount += 1
        if shouldFailDelete {
            throw MockError.deleteFailed
        }
        if let payslip = entity as? PayslipItem {
            testPayslips.removeAll { $0.id == payslip.id }
        }
    }
    
    func clearAllData() async throws {
        clearCallCount += 1
        if shouldFailClear {
            throw MockError.clearAllDataFailed
        }
        testPayslips.removeAll()
    }
    
    func reset() {
        isInitialized = false
        initializeCallCount = 0
        fetchCallCount = 0
        saveCount = 0
        deleteCount = 0
        clearCallCount = 0
        shouldFailSave = false
        shouldFailFetch = false
        shouldFailDelete = false
        shouldFailClear = false
        testPayslips.removeAll()
    }
}
*/