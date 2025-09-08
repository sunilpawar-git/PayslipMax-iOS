import Foundation
import SwiftData

/// Utility class for payslip migration operations
/// Handles migration logic and data transformation
/// Follows SOLID principles with single responsibility focus
@MainActor
final class PayslipMigrationUtilities {

    // MARK: - Properties

    private let migrationManager: PayslipMigrationManager

    // MARK: - Initialization

    init(migrationManager: PayslipMigrationManager) {
        self.migrationManager = migrationManager
    }

    // MARK: - Migration Operations

    /// Migrates a single payslip item to the latest schema version
    /// - Parameter payslip: The payslip item to migrate
    /// - Returns: Migrated payslip item
    /// - Throws: Migration error if migration fails
    func migrateItem(_ payslip: PayslipItem) async throws -> PayslipItem {
        try await migrationManager.migrateToLatest(payslip)
    }

    /// Migrates multiple payslip items in parallel
    /// - Parameter items: Array of payslip items to migrate
    /// - Returns: Array of migrated payslip items
    /// - Throws: Migration error if any migration fails
    func migrateItems(_ items: [PayslipItem]) async throws -> [PayslipItem] {
        // Process migrations in parallel for better performance
        async let migrations = items.concurrentMap { [self] item in
            try await migrationManager.migrateToLatest(item)
        }

        do {
            return try await migrations
        } catch {
            throw PayslipRepositoryError.migrationFailed(error)
        }
    }

    /// Migrates items if needed with error handling
    /// - Parameter items: Array of payslip items that may need migration
    /// - Returns: Array of migrated payslip items
    /// - Throws: Migration error if migration fails
    func migrateItemsIfNeeded(_ items: [PayslipItem]) async throws -> [PayslipItem] {
        try await migrateItems(items)
    }
}

// MARK: - Concurrent Processing Extensions

private extension Array {
    func concurrentMap<T>(_ transform: @escaping (Element) async throws -> T) async throws -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }

        return try await tasks.asyncMap { task in
            try await task.value
        }
    }
}

private extension Array {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()
        values.reserveCapacity(count)

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}
