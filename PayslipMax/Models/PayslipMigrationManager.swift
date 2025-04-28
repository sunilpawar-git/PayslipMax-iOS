import Foundation
import SwiftData

/// Manages the migration of `PayslipItem` data between different schema versions.
///
/// This class provides methods to migrate individual or all payslip items stored in the
/// provided `ModelContext` to the latest schema version defined in `PayslipSchemaVersion`.
final class PayslipMigrationManager {
    // MARK: - Properties
    
    /// The SwiftData model context used for fetching and updating payslip items.
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    /// Initializes the migration manager with a specific model context.
    /// - Parameter modelContext: The `ModelContext` containing the `PayslipItem` data to be migrated.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// Migrates a single payslip item to the latest schema version.
    /// Checks the item's current schema version and applies necessary migration steps.
    /// - Parameter item: The `PayslipItem` instance to migrate.
    /// - Returns: The migrated `PayslipItem` instance (potentially the same instance if already up-to-date).
    /// - Throws: `PayslipMigrationError` if migration fails.
    func migrateToLatest(_ item: PayslipItem) async throws -> PayslipItem {
        let currentVersion = PayslipSchemaVersion(rawValue: item.schemaVersion) ?? .v1
        
        switch currentVersion {
        case .v1:
            return try await migrateToV2(item)
        case .v2:
            return item // Already at latest version
        }
    }
    
    /// Iterates through all `PayslipItem` instances in the model context and migrates
    /// those that are not at the latest schema version.
    /// - Returns: The total number of items successfully migrated.
    /// - Throws: `PayslipMigrationError` or errors from `ModelContext.fetch` if migration fails.
    func migrateAllToLatest() async throws -> Int {
        let descriptor = FetchDescriptor<PayslipItem>()
        let items = try modelContext.fetch(descriptor)
        
        var migratedCount = 0
        for item in items {
            if let currentVersion = PayslipSchemaVersion(rawValue: item.schemaVersion),
               currentVersion < .v2 {
                _ = try await migrateToV2(item)
                migratedCount += 1
            }
        }
        
        return migratedCount
    }
    
    // MARK: - Private Methods
    
    /// Performs the specific migration steps to upgrade a `PayslipItem` from schema v1 to v2.
    ///
    /// **Migration Steps (v1 -> v2):**
    /// 1. Initializes `metadata` dictionary if it's empty.
    /// 2. Handles potential legacy data format conversions (example shown for "legacyFormat" key).
    /// 3. Updates `encryptionVersion` to 2 if it's lower.
    /// 4. Sets the `schemaVersion` property to `v2`.
    ///
    /// - Parameter item: The v1 `PayslipItem` to migrate.
    /// - Returns: The migrated `PayslipItem` (updated in place).
    /// - Throws: Potential errors during data conversion or encryption updates (if applicable in future steps).
    private func migrateToV2(_ item: PayslipItem) async throws -> PayslipItem {
        // 1. Ensure all required properties are initialized
        if item.metadata.isEmpty {
            item.metadata = [:]
        }
        
        // 2. Convert legacy data formats if needed
        if item.metadata.keys.contains("legacyFormat") {
            // Handle any legacy format conversions here
            item.metadata.removeValue(forKey: "legacyFormat")
        }
        
        // 3. Update encryption status if needed
        if item.encryptionVersion < 2 {
            item.encryptionVersion = 2
        }
        
        // 4. Update schema version
        item.schemaVersion = PayslipSchemaVersion.v2.rawValue
        
        return item
    }
}

// MARK: - Migration Errors

/// Defines errors that can occur during the payslip data migration process.
enum PayslipMigrationError: Error {
    /// General migration failure with a specific reason.
    case migrationFailed(String)
    /// The schema version found on an item is invalid or unexpected.
    case invalidSchemaVersion
    /// An error occurred during data encryption or decryption as part of the migration.
    case encryptionError(Error)
    
    /// Provides a user-friendly description for each migration error case.
    var localizedDescription: String {
        switch self {
        case .migrationFailed(let reason):
            return "Migration failed: \(reason)"
        case .invalidSchemaVersion:
            return "Invalid schema version"
        case .encryptionError(let error):
            return "Encryption error during migration: \(error.localizedDescription)"
        }
    }
} 