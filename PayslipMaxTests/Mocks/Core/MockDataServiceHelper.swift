import Foundation
@testable import Payslip_Max

// MARK: - Mock Data Service Helper
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
    
    func fetchRefreshed<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        // For testing purposes, just forward to regular fetch but mark it as a refresh
        fetchCallCount += 1
        if shouldFailFetch {
            throw MockError.fetchFailed
        }
        if type is PayslipItem.Type {
            print("MockDataServiceHelper: Refreshed fetch of \(testPayslips.count) items")
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