import Foundation
import SwiftData

// Since the protocol is already marked @MainActor, DataServiceImpl doesn't need to be marked @MainActor again
/// Provides an implementation of `DataServiceProtocol` using SwiftData and a repository pattern.
/// Handles saving, fetching, and deleting data, primarily focused on `PayslipItem` objects.
/// Requires a `SecurityServiceProtocol` for initialization checks.
final class DataServiceImpl: DataServiceProtocol {
    // MARK: - Properties
    /// The security service used for initialization and potential future security checks.
    private let securityService: SecurityServiceProtocol
    /// The SwiftData model context used for data operations.
    private let modelContext: ModelContext
    /// The repository responsible for direct interaction with `PayslipItem` data.
    private let payslipRepository: PayslipRepositoryProtocol
    
    /// Flag indicating if the service (including the security service dependency) is initialized.
    var isInitialized: Bool = false
    
    // MARK: - Initialization
    /// Initializes the data service with a security service.
    /// Creates a default `ModelContainer` and `ModelContext` for `PayslipItem`.
    /// Resolves the `PayslipRepositoryProtocol` dependency via `DIContainer`.
    /// - Parameter securityService: The security service dependency.
    init(securityService: SecurityServiceProtocol) {
        let modelContainer = try! ModelContainer(for: PayslipItem.self)
        let context = ModelContext(modelContainer)
        
        self.securityService = securityService
        self.modelContext = context
        self.payslipRepository = DIContainer.shared.makePayslipRepository(modelContext: context)
    }
    
    /// Initializes the data service with a security service and a specific model context.
    /// Resolves the `PayslipRepositoryProtocol` dependency via `DIContainer`.
    /// - Parameters:
    ///   - securityService: The security service dependency.
    ///   - modelContext: The specific `ModelContext` to use for data operations.
    init(securityService: SecurityServiceProtocol, modelContext: ModelContext) {
        self.securityService = securityService
        self.modelContext = modelContext
        self.payslipRepository = DIContainer.shared.makePayslipRepository(modelContext: modelContext)
    }
    
    /// Initializes the data service for testing with explicit dependencies.
    /// - Parameters:
    ///   - securityService: The security service dependency.
    ///   - modelContext: The specific `ModelContext` to use.
    ///   - payslipRepository: The specific `PayslipRepositoryProtocol` implementation to use.
    init(securityService: SecurityServiceProtocol, modelContext: ModelContext, payslipRepository: PayslipRepositoryProtocol) {
        self.securityService = securityService
        self.modelContext = modelContext
        self.payslipRepository = payslipRepository
    }
    
    // MARK: - ServiceProtocol
    /// Initializes the underlying security service.
    /// Sets the `isInitialized` flag upon success.
    /// - Throws: Errors from the `securityService.initialize()` call.
    func initialize() async throws {
        try await securityService.initialize()
        isInitialized = true
    }
    
    // MARK: - DataServiceProtocol
    /// Saves a single identifiable item.
    /// Currently supports only `PayslipItem` via the repository.
    /// Performs lazy initialization if the service is not already initialized.
    /// - Parameter item: The item to save.
    /// - Throws: `DataError.unsupportedType` if the item type is not `PayslipItem`.
    ///         `DataError.saveFailed` wrapping any error from the repository.
    ///         Errors from `initialize()` if lazy initialization fails.
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
    
    /// Saves a batch of identifiable items.
    /// Currently supports only `PayslipItem` via the repository.
    /// Performs lazy initialization if the service is not already initialized.
    /// - Parameter items: The array of items to save.
    /// - Throws: `DataError.unsupportedType` if the items type is not `[PayslipItem]` or the array is empty.
    ///         `DataError.saveFailed` wrapping any error from the repository.
    ///         Errors from `initialize()` if lazy initialization fails.
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
    
    /// Fetches all items of a specific identifiable type.
    /// Currently supports only `PayslipItem` via the repository.
    /// Performs lazy initialization if the service is not already initialized.
    /// - Parameter type: The type of item to fetch (e.g., `PayslipItem.self`).
    /// - Returns: An array of the fetched items.
    /// - Throws: `DataError.unsupportedType` if the type is not `PayslipItem.self`.
    ///         `DataError.fetchFailed` wrapping any error from the repository.
    ///         Errors from `initialize()` if lazy initialization fails.
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
    
    /// Deletes a single identifiable item.
    /// Currently supports only `PayslipItem` via the repository.
    /// Performs lazy initialization if the service is not already initialized.
    /// - Parameter item: The item to delete.
    /// - Throws: `DataError.unsupportedType` if the item type is not `PayslipItem`.
    ///         `DataError.deleteFailed` wrapping any error from the repository.
    ///         Errors from `initialize()` if lazy initialization fails.
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
    
    /// Deletes a batch of identifiable items.
    /// Currently supports only `PayslipItem` via the repository.
    /// Performs lazy initialization if the service is not already initialized.
    /// - Parameter items: The array of items to delete.
    /// - Throws: `DataError.unsupportedType` if the items type is not `[PayslipItem]` or the array is empty.
    ///         `DataError.deleteFailed` wrapping any error from the repository.
    ///         Errors from `initialize()` if lazy initialization fails.
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
    
    /// Deletes all data managed by this service (currently all `PayslipItem`s).
    /// Performs lazy initialization if the service is not already initialized.
    /// - Throws: `DataError.deleteFailed` wrapping any error from the repository.
    ///         Errors from `initialize()` if lazy initialization fails.
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