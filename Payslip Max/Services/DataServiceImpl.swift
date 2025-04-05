import Foundation
import SwiftData

// Since the protocol is already marked @MainActor, DataServiceImpl doesn't need to be marked @MainActor again
final class DataServiceImpl: DataServiceProtocol {
    // MARK: - Properties
    private let securityService: SecurityServiceProtocol
    private let modelContext: ModelContext
    var isInitialized: Bool = false
    
    // MARK: - Initialization
    init(securityService: SecurityServiceProtocol) {
        let modelContainer = try! ModelContainer(for: PayslipItem.self)
        let context = ModelContext(modelContainer)
        
        self.securityService = securityService
        self.modelContext = context
    }
    
    init(securityService: SecurityServiceProtocol, modelContext: ModelContext) {
        self.securityService = securityService
        self.modelContext = modelContext
    }
    
    // MARK: - ServiceProtocol
    func initialize() async throws {
        try await securityService.initialize()
        isInitialized = true
    }
    
    // MARK: - DataServiceProtocol
    func save<T>(_ item: T) async throws where T: Identifiable {
        // Lazy initialization if needed
        if !isInitialized {
            try await initialize()
        }
        
        if let payslip = item as? PayslipItem {
            // Store in SwiftData
            modelContext.insert(payslip)
            try modelContext.save()
        } else {
            throw DataError.unsupportedType
        }
    }
    
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        // Lazy initialization if needed
        if !isInitialized {
            try await initialize()
        }
        
        if type == PayslipItem.self {
            let descriptor = FetchDescriptor<PayslipItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
            let items = try modelContext.fetch(descriptor)
            return items as! [T]
        }
        
        throw DataError.unsupportedType
    }
    
    func delete<T>(_ item: T) async throws where T: Identifiable {
        // Lazy initialization if needed
        if !isInitialized {
            try await initialize()
        }
        
        if let payslip = item as? PayslipItem {
            modelContext.delete(payslip)
            try modelContext.save()
        } else {
            throw DataError.unsupportedType
        }
    }
    
    func clearAllData() async throws {
        // Lazy initialization if needed
        if !isInitialized {
            try await initialize()
        }
        
        // Delete all payslips
        let descriptor = FetchDescriptor<PayslipItem>()
        let items = try modelContext.fetch(descriptor)
        
        for item in items {
            modelContext.delete(item)
        }
        
        try modelContext.save()
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