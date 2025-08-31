import Foundation
import SwiftData

// Since the protocol is already marked @MainActor, DataServiceImpl doesn't need to be marked @MainActor again
/// Provides an implementation of `DataServiceProtocol` using SwiftData and a repository pattern.
///
/// This service acts as the primary data access layer for the application, handling all persistence
/// operations for `PayslipItem` objects. It implements a repository pattern to separate data access
/// concerns from business logic, and uses SwiftData for efficient persistence.
///
/// Key Features:
/// - Lazy initialization with security service integration
/// - Batch operations for efficient data handling
/// - Type-safe data operations with generic constraints
/// - Error handling with detailed error types
/// - Automatic schema migration support
///
/// Architecture:
/// - Uses SwiftData's `ModelContext` for persistence
/// - Delegates to `PayslipRepositoryProtocol` for payslip-specific operations
/// - Integrates with `SecurityServiceProtocol` for initialization checks
///
/// Usage:
/// ```swift
/// let dataService = DataServiceImpl(securityService: securityService)
/// try await dataService.initialize()
/// let payslips = try await dataService.fetch(PayslipItem.self)
/// ```
///
/// Error Handling:
/// - `DataError.notInitialized`: Service not properly initialized
/// - `DataError.unsupportedType`: Attempted operation on unsupported type
/// - `DataError.saveFailed`: Error during save operation
/// - `DataError.fetchFailed`: Error during fetch operation
/// - `DataError.deleteFailed`: Error during delete operation
///
/// Thread Safety:
/// - All operations are marked with @MainActor to ensure thread safety
/// - Batch operations are processed in chunks to avoid memory issues
/// - Concurrent operations are handled safely through SwiftData's context
final class DataServiceImpl: DataServiceProtocol {
    // MARK: - Properties
    /// The security service used for initialization and potential future security checks.
    private let securityService: SecurityServiceProtocol
    /// The SwiftData model context used for data operations.
    private let modelContext: ModelContext
    /// The repository responsible for direct interaction with `PayslipItem` data.
    private var payslipRepository: PayslipRepositoryProtocol?
    
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
        self.payslipRepository = nil // Initialize lazily
    }
    
    /// Initializes the data service for testing with explicit dependencies.
    /// - Parameters:
    ///   - securityService: The security service dependency.
    ///   - modelContext: The specific `ModelContext` to use.
    ///   - payslipRepository: The specific `PayslipRepositoryProtocol` implementation to use.
    init(securityService: SecurityServiceProtocol, modelContext: ModelContext) {
        self.securityService = securityService
        self.modelContext = modelContext
        self.payslipRepository = nil // Initialize lazily
    }

    // New initializer for lazy repository setup
    private func setupPayslipRepository() {
        if self.payslipRepository == nil {
            self.payslipRepository = DIContainer.shared.makePayslipRepository(modelContext: self.modelContext)
        }
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
            // Setup repository if needed
            setupPayslipRepository()
            // Phase 14: Gate saving for legacy PCDA when builder gating is enabled and result is low-confidence
            if shouldBlockSaveForPCDA(payslip) {
                // Surface Review state and context to UI
                payslip.status = "Review"
                var meta = payslip.metadata
                meta["pcdaReviewReason"] = "Totals derived from components without passing validator. Please review."
                payslip.metadata = meta
                throw DataError.saveFailed(NSError(domain: "PCDA", code: 14, userInfo: [NSLocalizedDescriptionKey: "PCDA validation failed: Review required before save"]))
            }
            try await payslipRepository?.savePayslip(payslip)
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
            // Setup repository if needed
            setupPayslipRepository()
            // Phase 14: Filter out items that should be review-gated
            let toSave = payslips.filter { !shouldBlockSaveForPCDA($0) }
            try await payslipRepository?.savePayslips(toSave)
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
            // Setup repository if needed
            setupPayslipRepository()
            let payslips = try await payslipRepository?.fetchAllPayslips() ?? []
            return payslips as! [T]
        }
        
        throw DataError.unsupportedType
    }
    
    /// Fetches all items of a specific identifiable type, ensuring a fresh fetch from the database.
    /// This method helps ensure that the latest data is retrieved by bypassing any caching layers.
    /// Currently supports only `PayslipItem` via the repository.
    /// - Parameter type: The type of item to fetch (e.g., `PayslipItem.self`).
    /// - Returns: An array of the freshly fetched items.
    /// - Throws: `DataError.unsupportedType` if the type is not `PayslipItem.self`.
    ///         `DataError.fetchFailed` wrapping any error from the repository.
    ///         Errors from `initialize()` if lazy initialization fails.
    func fetchRefreshed<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        // Lazy initialization if needed
        if !isInitialized {
            try await initialize()
        }
        
        if type == PayslipItem.self {
            // First invalidate any caches and process pending changes
            modelContext.processPendingChanges()
            
            // Reset SwiftData's in-memory state to ensure fresh data
            // Note: SwiftData doesn't have a direct refreshAll equivalent, 
            // so we'll use processPendingChanges() which helps flush pending operations
            modelContext.processPendingChanges()
            
            // Small delay to allow context operations to complete
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            
            // Then explicitly fetch with a fresh descriptor
            var descriptor = FetchDescriptor<PayslipItem>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            
            // Turn off any batch limits to ensure we get everything
            descriptor.fetchLimit = 0
            
            // Use a predicate to force a non-cached fetch
            descriptor.predicate = #Predicate<PayslipItem> { _ in true }
            
            // Perform the fresh fetch
            let items = try modelContext.fetch(descriptor)
            print("DataService: Refreshed fetch returned \(items.count) items")
            
            return items as! [T]
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
            // Process any pending changes before deletion
            modelContext.processPendingChanges()
            
            // First ensure the item is deleted from the current context
            modelContext.delete(payslip)
            
            // Save immediately
            try modelContext.save()
            
            // Setup repository if needed
            setupPayslipRepository()
            // Then use the repository to ensure it's deleted from all contexts
            try await payslipRepository?.deletePayslip(payslip)
            
            // Process changes again after deletion
            modelContext.processPendingChanges()
            
            print("DataService: Item deleted successfully")
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
            // Setup repository if needed
            setupPayslipRepository()
            try await payslipRepository?.deletePayslips(payslips)
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
        
        // Setup repository if needed
        setupPayslipRepository()
        // Delete all payslips using the repository
        try await payslipRepository?.deleteAllPayslips()
    }
    
    // MARK: - Public Utility Methods
    
    /// Process any pending changes in the model context
    /// This helps flush operations and ensure the database state is consistent
    func processPendingChanges() {
        modelContext.processPendingChanges()
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

// MARK: - Phase 14: Save Gating Helpers
private extension DataServiceImpl {
    func shouldBlockSaveForPCDA(_ payslip: PayslipItem) -> Bool {
        // Only when feature flag is enabled
        let flags = ServiceRegistry.shared.resolve(FeatureFlagProtocol.self)
        guard flags?.isEnabled(.pcdaBuilderGating) == true else { return false }
        // Heuristic: legacy PCDA path sets special keys in earnings/deductions
        let hasPCDATotals = payslip.earnings.keys.contains("__CREDITS_TOTAL") || payslip.deductions.keys.contains("__DEBITS_TOTAL")
        guard hasPCDATotals else { return false }
        // If totals were derived purely from component sums and validator enforcement is enabled and failed, block
        // Since we do not carry validation result on the model, conservatively block when credits or debits are zeros while components exist
        let componentsPresent = (!payslip.earnings.isEmpty || !payslip.deductions.isEmpty)
        let totalsNonPositive = (payslip.credits <= 0 || payslip.debits <= 0)
        return componentsPresent && totalsNonPositive
    }
}