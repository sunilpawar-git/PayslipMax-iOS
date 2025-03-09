import Foundation
import SwiftData

final class DataServiceImpl: DataServiceProtocol {
    // MARK: - Properties
    private let security: SecurityServiceProtocol
    private let modelContext: ModelContext
    var isInitialized: Bool = false
    
    // MARK: - Initialization
    init(security: SecurityServiceProtocol, modelContext: ModelContext) {
        self.security = security
        self.modelContext = modelContext
    }
    
    // MARK: - ServiceProtocol
    func initialize() async throws {
        try await security.initialize()
        isInitialized = true
    }
    
    // MARK: - DataServiceProtocol
    func save<T: Codable>(_ item: T) async throws {
        guard isInitialized else {
            throw DataError.notInitialized
        }
        
        do {
            let data = try JSONEncoder().encode(item)
            _ = try await security.encrypt(data) // We're not using the encrypted data since we're using SwiftData
            
            // Store in SwiftData - dispatch to main actor
            if let payslip = item as? PayslipItem {
                try await MainActor.run {
                    modelContext.insert(payslip)
                    try modelContext.save()
                }
            }
        } catch {
            throw DataError.saveFailed(error)
        }
    }
    
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T] {
        guard isInitialized else {
            throw DataError.notInitialized
        }
        
        do {
            if type == PayslipItem.self {
                // Fetch on the main actor
                return try await MainActor.run {
                    let descriptor = FetchDescriptor<PayslipItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
                    let items = try modelContext.fetch(descriptor)
                    return items as! [T]
                }
            }
            throw DataError.unsupportedType
        } catch {
            throw DataError.fetchFailed(error)
        }
    }
    
    func delete<T: Codable>(_ item: T) async throws {
        guard isInitialized else {
            throw DataError.notInitialized
        }
        
        do {
            if let payslip = item as? PayslipItem {
                // Delete on the main actor
                try await MainActor.run {
                    modelContext.delete(payslip)
                    try modelContext.save()
                }
            } else {
                throw DataError.unsupportedType
            }
        } catch {
            throw DataError.deleteFailed(error)
        }
    }
    
    // MARK: - Error Types
    enum DataError: LocalizedError {
        case notInitialized
        case unsupportedType
        case saveFailed(Error)
        case fetchFailed(Error)
        case deleteFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .notInitialized:
                return "Data service not initialized"
            case .unsupportedType:
                return "Unsupported data type"
            case .saveFailed(let error):
                return "Failed to save data: \(error.localizedDescription)"
            case .fetchFailed(let error):
                return "Failed to fetch data: \(error.localizedDescription)"
            case .deleteFailed(let error):
                return "Failed to delete data: \(error.localizedDescription)"
            }
        }
    }
} 