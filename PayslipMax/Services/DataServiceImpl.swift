import Foundation
import SwiftData

/// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
/// Current: 125 lines / 300 lines
/// Next action at 250 lines: Extract components

/// Provides an implementation of `DataServiceProtocol` using component-based architecture.
/// Since the protocol is already marked @MainActor, DataServiceImpl needs to be marked @MainActor as well.
///
/// This service acts as the primary data access layer for the application, handling all persistence
/// operations for `PayslipItem` objects. It implements a repository pattern with component extraction
/// to maintain clean architecture and separation of concerns.
///
/// Key Features:
/// - Component-based architecture with single responsibility per component
/// - Lazy initialization with security service integration
/// - Batch operations for efficient data handling
/// - Type-safe data operations with generic constraints
/// - Error handling with detailed error types
/// - Automatic schema migration support
///
/// Architecture:
/// - `DataServiceCore`: Handles properties and initialization
/// - `DataServiceOperations`: Contains all CRUD operations
/// - `DataServiceSupport`: Provides utility methods and helpers
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
@MainActor
final class DataServiceImpl: DataServiceProtocol {
    // MARK: - Component Composition
    /// Core component handling properties and initialization
    private let core: DataServiceCore
    /// Operations component handling all CRUD operations
    private let operations: DataServiceOperations
    /// Support component providing utility methods
    private let support: DataServiceSupport

    /// Computed property to expose initialization state from core component
    var isInitialized: Bool {
        core.isInitialized
    }

    // MARK: - Initialization
    /// Initializes the data service with a security service.
    /// Creates component instances and sets up the component composition architecture.
    /// - Parameter securityService: The security service dependency.
    /// - Throws: ModelContainer creation errors from core component
    init(securityService: SecurityServiceProtocol) throws {
        // Initialize core component first
        self.core = try DataServiceCore(securityService: securityService)

        // Initialize dependent components
        self.operations = DataServiceOperations(core: core)
        self.support = DataServiceSupport(core: core)
    }

    /// Initializes the data service for testing with explicit dependencies.
    /// - Parameters:
    ///   - securityService: The security service dependency.
    ///   - modelContext: The specific `ModelContext` to use.
    init(securityService: SecurityServiceProtocol, modelContext: ModelContext) {
        // Initialize core component with test dependencies
        self.core = DataServiceCore(securityService: securityService, modelContext: modelContext)

        // Initialize dependent components
        self.operations = DataServiceOperations(core: core)
        self.support = DataServiceSupport(core: core)
    }

    // MARK: - ServiceProtocol Implementation
    /// Initializes the underlying security service through the core component.
    /// - Throws: Errors from the `securityService.initialize()` call.
    func initialize() async throws {
        try await core.initialize()
    }

    // MARK: - DataServiceProtocol Implementation
    /// Saves a single identifiable item using the operations component.
    /// - Parameter item: The item to save.
    /// - Throws: DataError for unsupported types or save failures.
    func save<T>(_ item: T) async throws where T: Identifiable {
        try await core.ensureInitialized()
        try await operations.save(item)
    }

    /// Saves a batch of identifiable items using the operations component.
    /// - Parameter items: The array of items to save.
    /// - Throws: DataError for unsupported types or save failures.
    func saveBatch<T>(_ items: [T]) async throws where T: Identifiable {
        try await core.ensureInitialized()
        try await operations.saveBatch(items)
    }

    /// Fetches all items of a specific identifiable type using the operations component.
    /// - Parameter type: The type of item to fetch (e.g., `PayslipItem.self`).
    /// - Returns: An array of the fetched items.
    /// - Throws: DataError for unsupported types or fetch failures.
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        try await core.ensureInitialized()
        return try await operations.fetch(type)
    }

    /// Fetches all items with a fresh query using the operations component.
    /// - Parameter type: The type of item to fetch (e.g., `PayslipItem.self`).
    /// - Returns: An array of the freshly fetched items.
    /// - Throws: DataError for unsupported types or fetch failures.
    func fetchRefreshed<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        try await core.ensureInitialized()
        return try await operations.fetchRefreshed(type)
    }

    /// Deletes a single identifiable item using the operations component.
    /// - Parameter item: The item to delete.
    /// - Throws: DataError for unsupported types or delete failures.
    func delete<T>(_ item: T) async throws where T: Identifiable {
        try await core.ensureInitialized()
        try await operations.delete(item)
    }

    /// Deletes a batch of identifiable items using the operations component.
    /// - Parameter items: The array of items to delete.
    /// - Throws: DataError for unsupported types or delete failures.
    func deleteBatch<T>(_ items: [T]) async throws where T: Identifiable {
        try await core.ensureInitialized()
        try await operations.deleteBatch(items)
    }

    /// Deletes all data using the operations component.
    /// - Throws: DataError for delete failures.
    func clearAllData() async throws {
        try await core.ensureInitialized()
        try await operations.clearAllData()
    }

    // MARK: - Public Utility Methods
    /// Process any pending changes in the model context using the support component.
    func processPendingChanges() {
        support.processPendingChanges()
    }
}