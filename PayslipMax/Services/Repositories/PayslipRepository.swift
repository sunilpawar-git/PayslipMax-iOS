import Foundation
import SwiftData

/// Errors that can occur during repository operations
enum PayslipRepositoryError: LocalizedError {
    case batchSaveFailed(successful: Int, failed: Int, lastError: Error?)
    case invalidUUIDFormat
    case migrationFailed(Error)
    case queryFailed(Error)
    case invalidPredicate
    case unsupportedPredicateOperator

    var errorDescription: String? {
        switch self {
        case .batchSaveFailed(let successful, let failed, let lastError):
            var description = "Failed to save \(failed) payslips (successfully saved \(successful))"
            if let lastError = lastError {
                description += "\nLast error: \(lastError.localizedDescription)"
            }
            return description
        case .invalidUUIDFormat:
            return "Invalid UUID format"
        case .migrationFailed(let error):
            return "Migration failed: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "Query failed: \(error.localizedDescription)"
        case .invalidPredicate:
            return "Invalid predicate format"
        case .unsupportedPredicateOperator:
            return "Unsupported predicate operator"
        }
    }
}

/// Implementation of the PayslipRepositoryProtocol that uses SwiftData for persistence
/// Orchestrates repository operations using extracted utility classes
/// Follows SOLID principles with single responsibility focus
@MainActor
final class PayslipRepository: PayslipRepositoryProtocol {
    // MARK: - Properties

    private let modelContext: ModelContext
    private let modelContainer: ModelContainer

    // Utility classes
    private let queryBuilder = PayslipQueryBuilder()
    private let migrationUtilities: PayslipMigrationUtilities
    private let batchOperations: PayslipBatchOperations

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.modelContainer = modelContext.container

        let migrationManager = PayslipMigrationManager(modelContext: modelContext)
        self.migrationUtilities = PayslipMigrationUtilities(migrationManager: migrationManager)
        self.batchOperations = PayslipBatchOperations(
            modelContext: modelContext,
            migrationUtilities: migrationUtilities
        )
    }
    
    // MARK: - PayslipRepositoryProtocol

    func fetchAllPayslips() async throws -> [PayslipItem] {
        let descriptor = PayslipQueryBuilder.fetchAllDescriptor()
        let items = try modelContext.fetch(descriptor)
        return try await migrationUtilities.migrateItemsIfNeeded(items)
    }

    func fetchPayslips(withFilter filter: NSPredicate?) async throws -> [PayslipItem] {
        let predicate = try filter.map { try PayslipPredicateConverter.convertNSPredicateToPredicate($0) }
        let descriptor = PayslipQueryBuilder.fetchWithFilterDescriptor(filter: predicate)
        let items = try modelContext.fetch(descriptor)
        return try await migrationUtilities.migrateItemsIfNeeded(items)
    }

    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipItem] {
        let descriptor = PayslipQueryBuilder.fetchDateRangeDescriptor(fromDate: fromDate, toDate: toDate)

        do {
            let items = try modelContext.fetch(descriptor)
            return try await migrationUtilities.migrateItemsIfNeeded(items)
        } catch {
            throw PayslipRepositoryError.queryFailed(error)
        }
    }

    func fetchPayslip(byId id: String) async throws -> PayslipItem? {
        guard let uuid = UUID(uuidString: id) else {
            throw PayslipRepositoryError.invalidUUIDFormat
        }

        let descriptor = PayslipQueryBuilder.fetchByIdDescriptor(uuid: uuid)
        let items = try modelContext.fetch(descriptor)
        return try await migrationUtilities.migrateItemsIfNeeded(items).first
    }

    func savePayslip(_ payslip: PayslipItem) async throws {
        do {
            _ = try await migrationUtilities.migrateItem(payslip)
            modelContext.insert(payslip)
            try modelContext.save()
        } catch {
            throw PayslipRepositoryError.migrationFailed(error)
        }
    }

    func savePayslips(_ payslips: [PayslipItem]) async throws {
        try await batchOperations.savePayslips(payslips)
    }

    func deletePayslip(_ payslip: PayslipItem) async throws {
        modelContext.delete(payslip)
        try modelContext.save()
    }

    func deletePayslips(_ payslips: [PayslipItem]) async throws {
        try await batchOperations.deletePayslips(payslips)
    }

    func deleteAllPayslips() async throws {
        try await batchOperations.deleteAllPayslips()
    }

    func countPayslips() async throws -> Int {
        let descriptor = PayslipQueryBuilder.fetchCountDescriptor()
        return try modelContext.fetchCount(descriptor)
    }
    
    // MARK: - Public Methods

    /// Fetches payslips with pagination support
    /// - Parameters:
    ///   - page: The page number (0-based)
    ///   - pageSize: Number of items per page
    ///   - filter: Optional predicate to filter results
    ///   - sortBy: KeyPath to sort by
    ///   - ascending: Sort direction
    /// - Returns: Tuple containing the fetched items and total count
    func fetchPayslipsPaginated(
        page: Int = 0,
        pageSize: Int = 20,
        filter: NSPredicate? = nil,
        sortBy: KeyPath<PayslipItem, some Comparable> = \PayslipItem.timestamp,
        ascending: Bool = false
    ) async throws -> (items: [PayslipItem], totalCount: Int) {
        let predicate = try filter.map { try PayslipPredicateConverter.convertNSPredicateToPredicate($0) }
        let descriptor = PayslipQueryBuilder.fetchPaginatedDescriptor(
            page: page,
            pageSize: pageSize,
            filter: predicate,
            sortBy: sortBy,
            ascending: ascending
        )

        // Get total count first
        let countDescriptor = PayslipQueryBuilder.fetchCountDescriptor(filter: predicate)
        let totalCount = try modelContext.fetchCount(countDescriptor)

        // Fetch items
        let items = try modelContext.fetch(descriptor)
        return (try await migrationUtilities.migrateItemsIfNeeded(items), totalCount)
    }
}

