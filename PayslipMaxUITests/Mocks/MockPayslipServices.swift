import Foundation

// MARK: - Data Service Protocol

/// Protocol for data storage services
protocol DataServiceProtocol: ServiceProtocol {
    func fetchAllPayslips() throws -> [any PayslipItemProtocol]
    func fetchPayslip(with id: UUID) throws -> (any PayslipItemProtocol)?
    func save(_ payslip: any PayslipItemProtocol) throws
    func delete(_ payslip: any PayslipItemProtocol) throws
    func deleteAll() throws
    
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable
    func save<T>(_ entity: T) async throws where T: Identifiable
    func delete<T>(_ entity: T) async throws where T: Identifiable
    func clearAllData() async throws
}

// MARK: - Mock Data Service
class MockDataService: DataServiceProtocol {
    var payslips: [any PayslipItemProtocol] = []
    var fetchError: Error?
    var saveError: Error?
    var deleteError: Error?
    var isInitialized: Bool = true
    
    func reset() {
        payslips = []
        fetchError = nil
        saveError = nil
        deleteError = nil
    }
    
    func initialize() async throws {
        // No-op implementation for testing
    }
    
    func fetchAllPayslips() throws -> [any PayslipItemProtocol] {
        if let error = fetchError {
            throw error
        }
        return payslips
    }
    
    func fetchPayslip(with id: UUID) throws -> (any PayslipItemProtocol)? {
        if let error = fetchError {
            throw error
        }
        return payslips.first { $0.id == id }
    }
    
    func save(_ payslip: any PayslipItemProtocol) throws {
        if let error = saveError {
            throw error
        }
        
        if let index = payslips.firstIndex(where: { $0.id == payslip.id }) {
            payslips[index] = payslip
        } else {
            payslips.append(payslip)
        }
    }
    
    func delete(_ payslip: any PayslipItemProtocol) throws {
        if let error = deleteError {
            throw error
        }
        payslips.removeAll { $0.id == payslip.id }
    }
    
    func deleteAll() throws {
        if let error = deleteError {
            throw error
        }
        payslips = []
    }
    
    // Generic versions required by ServiceProtocol
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        if let error = fetchError {
            throw error
        }
        
        if type is PayslipItemProtocol.Type {
            return payslips as! [T] // Cast required, but should be safe
        }
        
        return [] // Return empty array for other types
    }
    
    func fetchRefreshed<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        // Same implementation as fetch for the mock
        if let error = fetchError {
            throw error
        }
        
        if type is PayslipItemProtocol.Type {
            return payslips as! [T]
        }
        
        return []
    }
    
    func save<T>(_ entity: T) async throws where T: Identifiable {
        if let error = saveError {
            throw error
        }
        if let payslip = entity as? any PayslipItemProtocol {
            if let index = payslips.firstIndex(where: { $0.id == payslip.id }) {
                payslips[index] = payslip
            } else {
                payslips.append(payslip)
            }
        }
    }
    
    func delete<T>(_ entity: T) async throws where T: Identifiable {
        if let error = deleteError {
            throw error
        }
        if let payslip = entity as? any PayslipItemProtocol {
            payslips.removeAll { $0.id == payslip.id }
        }
    }
    
    func clearAllData() async throws {
        if let error = deleteError {
            throw error
        }
        payslips = []
    }
} 