import Foundation
import SwiftData

// Since the protocol is already marked @MainActor, DataServiceImpl doesn't need to be marked @MainActor again
final class DataServiceImpl: DataServiceProtocol {
    // MARK: - Properties
    private let securityService: SecurityServiceProtocol
    private let modelContext: ModelContext
    private let payslipRepository: PayslipRepositoryProtocol
    
    var isInitialized: Bool = false
    
    // MARK: - Initialization
    init(securityService: SecurityServiceProtocol) {
        let modelContainer = try! ModelContainer(for: PayslipItem.self)
        let context = ModelContext(modelContainer)
        
        self.securityService = securityService
        self.modelContext = context
        self.payslipRepository = DIContainer.shared.makePayslipRepository(modelContext: context)
    }
    
    init(securityService: SecurityServiceProtocol, modelContext: ModelContext) {
        self.securityService = securityService
        self.modelContext = modelContext
        self.payslipRepository = DIContainer.shared.makePayslipRepository(modelContext: modelContext)
    }
    
    // For testing with a custom repository
    init(securityService: SecurityServiceProtocol, modelContext: ModelContext, payslipRepository: PayslipRepositoryProtocol) {
        self.securityService = securityService
        self.modelContext = modelContext
        self.payslipRepository = payslipRepository
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
            // Use the repository for PayslipItem
            try await payslipRepository.savePayslip(payslip)
        } else {
            throw DataError.unsupportedType
        }
    }
    
    func saveBatch<T>(_ items: [T]) async throws where T: Identifiable {
        // Lazy initialization if needed
        if !isInitialized {
            try await initialize()
        }
        
        if let payslips = items as? [PayslipItem], !payslips.isEmpty {
            try await payslipRepository.savePayslips(payslips)
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
            let payslips = try await payslipRepository.fetchAllPayslips()
            return payslips as! [T]
        }
        
        throw DataError.unsupportedType
    }
    
    func delete<T>(_ item: T) async throws where T: Identifiable {
        // Lazy initialization if needed
        if !isInitialized {
            try await initialize()
        }
        
        if let payslip = item as? PayslipItem {
            try await payslipRepository.deletePayslip(payslip)
        } else {
            throw DataError.unsupportedType
        }
    }
    
    func deleteBatch<T>(_ items: [T]) async throws where T: Identifiable {
        // Lazy initialization if needed
        if !isInitialized {
            try await initialize()
        }
        
        if let payslips = items as? [PayslipItem], !payslips.isEmpty {
            try await payslipRepository.deletePayslips(payslips)
        } else {
            throw DataError.unsupportedType
        }
    }
    
    func clearAllData() async throws {
        // Lazy initialization if needed
        if !isInitialized {
            try await initialize()
        }
        
        // Delete all payslips using the repository
        try await payslipRepository.deleteAllPayslips()
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