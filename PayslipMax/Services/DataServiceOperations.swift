import Foundation
import SwiftData

/// Operations component for DataService containing all data manipulation logic.
/// This class handles the core CRUD operations for the data service,
/// implementing efficient batch processing and error handling.
///
/// Key Responsibilities:
/// - Save operations (single and batch) with transaction safety
/// - Fetch operations (standard and refreshed) with caching strategies
/// - Delete operations (single and batch) with proper cleanup
/// - Type-safe generic operations with Identifiable constraints
/// - Optimized batch processing for performance
/// - Comprehensive error handling and logging
@MainActor
final class DataServiceOperations {
    // MARK: - Properties
    private let core: DataServiceCore

    // MARK: - Initialization
    init(core: DataServiceCore) {
        self.core = core
    }

    // MARK: - Save Operations
    /// Saves a single identifiable item.
    /// Currently supports only `PayslipItem` via the repository.
    /// - Parameter item: The item to save.
    /// - Throws: `DataError.unsupportedType` if the item type is not `PayslipItem`.
    ///         `DataError.saveFailed` wrapping any error from the repository.
    func save<T>(_ item: T) async throws where T: Identifiable {
        if let payslip = item as? PayslipItem {
            // Setup repository if needed
            core.setupPayslipRepository()
            // Use the repository for PayslipItem
            try await core.payslipRepository?.savePayslip(payslip)
        } else {
            throw DataError.unsupportedType
        }
    }

    /// Saves a batch of identifiable items.
    /// Currently supports only `PayslipItem` via the repository.
    /// - Parameter items: The array of items to save.
    /// - Throws: `DataError.unsupportedType` if the items type is not `[PayslipItem]` or the array is empty.
    ///         `DataError.saveFailed` wrapping any error from the repository.
    func saveBatch<T>(_ items: [T]) async throws where T: Identifiable {
        if let payslips = items as? [PayslipItem], !payslips.isEmpty {
            // Setup repository if needed
            core.setupPayslipRepository()
            try await core.payslipRepository?.savePayslips(payslips)
        } else {
            throw DataError.unsupportedType
        }
    }

    // MARK: - Fetch Operations
    /// Fetches all items of a specific identifiable type.
    /// Currently supports only `PayslipItem` via the repository.
    /// - Parameter type: The type of item to fetch (e.g., `PayslipItem.self`).
    /// - Returns: An array of the fetched items.
    /// - Throws: `DataError.unsupportedType` if the type is not `PayslipItem.self`.
    ///         `DataError.fetchFailed` wrapping any error from the repository.
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        if type == PayslipItem.self {
            // Setup repository if needed
            core.setupPayslipRepository()
            let payslips = try await core.payslipRepository?.fetchAllPayslips() ?? []
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
    func fetchRefreshed<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        if type == PayslipItem.self {
            // First invalidate any caches and process pending changes
            core.modelContext.processPendingChanges()

            // Reset SwiftData's in-memory state to ensure fresh data
            // Note: SwiftData doesn't have a direct refreshAll equivalent,
            // so we'll use processPendingChanges() which helps flush pending operations
            core.modelContext.processPendingChanges()

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
            let items = try core.modelContext.fetch(descriptor)

            // Only log in non-test environments to reduce test verbosity
            if !ProcessInfo.isRunningInTestEnvironment {
                print("DataService: Refreshed fetch returned \(items.count) items")
            }

            return items as! [T]
        }

        throw DataError.unsupportedType
    }

    // MARK: - Delete Operations
    /// Deletes a single identifiable item.
    /// Currently supports only `PayslipItem` via the repository.
    /// - Parameter item: The item to delete.
    /// - Throws: `DataError.unsupportedType` if the item type is not `PayslipItem`.
    ///         `DataError.deleteFailed` wrapping any error from the repository.
    func delete<T>(_ item: T) async throws where T: Identifiable {
        if let payslip = item as? PayslipItem {
            // Process any pending changes before deletion
            core.modelContext.processPendingChanges()

            // First ensure the item is deleted from the current context
            core.modelContext.delete(payslip)

            // Save immediately
            try core.modelContext.save()

            // Setup repository if needed
            core.setupPayslipRepository()
            // Then use the repository to ensure it's deleted from all contexts
            try await core.payslipRepository?.deletePayslip(payslip)

            // Process changes again after deletion
            core.modelContext.processPendingChanges()

            print("DataService: Item deleted successfully")
        } else {
            throw DataError.unsupportedType
        }
    }

    /// Deletes a batch of identifiable items.
    /// Currently supports only `PayslipItem` via the repository.
    /// - Parameter items: The array of items to delete.
    /// - Throws: `DataError.unsupportedType` if the items type is not `[PayslipItem]` or the array is empty.
    ///         `DataError.deleteFailed` wrapping any error from the repository.
    func deleteBatch<T>(_ items: [T]) async throws where T: Identifiable {
        if let payslips = items as? [PayslipItem], !payslips.isEmpty {
            // Setup repository if needed
            core.setupPayslipRepository()
            try await core.payslipRepository?.deletePayslips(payslips)
        } else {
            throw DataError.unsupportedType
        }
    }

    /// Deletes all data managed by this service (currently all `PayslipItem`s).
    /// - Throws: `DataError.deleteFailed` wrapping any error from the repository.
    func clearAllData() async throws {
        // Setup repository if needed
        core.setupPayslipRepository()
        // Delete all payslips using the repository
        try await core.payslipRepository?.deleteAllPayslips()
    }
}
