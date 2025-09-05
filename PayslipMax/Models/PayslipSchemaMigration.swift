import Foundation
import SwiftData

// MARK: - Schema Migration Support

/// Defines the versioned schema information for `PayslipItem`.
enum PayslipVersionedSchema: VersionedSchema {
    /// Lists the models included in this schema version. Currently only `PayslipItem`.
    static var models: [any PersistentModel.Type] {
        [PayslipItem.self]
    }
    
    /// The identifier for the current schema version (e.g., 2.0.0).
    static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0) // Current version
    }
    
    /// Specifies the migration plan used to migrate between schema versions.
    static var migrationPlan: SchemaMigrationPlan {
        PayslipMigrationPlan()
    }
}

/// Defines the migration plan and stages for moving between `PayslipItem` schema versions.
struct PayslipMigrationPlan: SchemaMigrationPlan {
    /// Lists the schema versions involved in this migration plan.
    static var schemas: [any VersionedSchema.Type] {
        [PayslipVersionedSchema.self]
    }
    
    /// Defines the sequence of migration stages.
    static var stages: [MigrationStage] {
        [
            // Stage 1: Migrate from v1 to v2
            migrate(from: PayslipVersionedSchema.self, to: PayslipVersionedSchema.self)
        ]
    }
    
    /// Creates a custom migration stage between two schema versions.
    /// Allows for custom logic to be executed before and after migration.
    /// - Parameters:
    ///   - sourceVersion: The source schema version type.
    ///   - destinationVersion: The destination schema version type.
    /// - Returns: A `MigrationStage` configured for the migration.
    static func migrate(from sourceVersion: any VersionedSchema.Type, to destinationVersion: any VersionedSchema.Type) -> MigrationStage {
        MigrationStage.custom(
            fromVersion: sourceVersion,
            toVersion: destinationVersion,
            willMigrate: { context in
                // Pre-migration tasks
                print("Starting migration from \(sourceVersion.versionIdentifier) to \(destinationVersion.versionIdentifier)")
            },
            didMigrate: { context in
                // Post-migration tasks
                print("Completed migration to \(destinationVersion.versionIdentifier)")
            }
        )
    }
}

// MARK: - Schema Extension

extension PayslipItem {
    /// The SwiftData schema definition, referencing the versioned schema.
    static var schema: Schema {
        Schema(versionedSchema: PayslipVersionedSchema.self)
    }
}
