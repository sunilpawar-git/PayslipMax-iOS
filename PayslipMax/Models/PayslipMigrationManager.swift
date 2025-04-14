import Foundation
import SwiftData

/// Manages the migration of PayslipItem data between schema versions
final class PayslipMigrationManager {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// Migrates a single payslip item to the latest schema version
    /// - Parameter item: The payslip item to migrate
    /// - Returns: The migrated payslip item
    func migrateToLatest(_ item: PayslipItem) async throws -> PayslipItem {
        let currentVersion = PayslipSchemaVersion(rawValue: item.schemaVersion) ?? .v1
        
        switch currentVersion {
        case .v1:
            return try await migrateToV2(item)
        case .v2:
            return item // Already at latest version
        }
    }
    
    /// Migrates all payslip items to the latest schema version
    /// - Returns: The number of items migrated
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
    
    /// Migrates a payslip item from version 1 to version 2
    /// - Parameter item: The payslip item to migrate
    /// - Returns: The migrated payslip item
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

enum PayslipMigrationError: Error {
    case migrationFailed(String)
    case invalidSchemaVersion
    case encryptionError(Error)
    
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