import Foundation
import SwiftData

/// Utility class for payslip batch operations
/// Handles batch saving, deletion, and processing operations
/// Follows SOLID principles with single responsibility focus
@MainActor
final class PayslipBatchOperations {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let migrationUtilities: PayslipMigrationUtilities
    private let batchSize = 50 // Optimal batch size for operations

    // MARK: - Initialization

    init(modelContext: ModelContext, migrationUtilities: PayslipMigrationUtilities) {
        self.modelContext = modelContext
        self.migrationUtilities = migrationUtilities
    }

    // MARK: - Batch Saving

    /// Saves multiple payslip items in optimized batches
    /// - Parameter payslips: Array of payslip items to save
    /// - Throws: BatchSaveFailed error if any batch operation fails
    func savePayslips(_ payslips: [PayslipItem]) async throws {
        guard !payslips.isEmpty else { return }

        // Process in batches to avoid memory issues
        for batch in payslips.chunked(into: batchSize) {
            try await processBatch(batch)
        }
    }

    /// Processes a single batch of payslip items for saving
    /// - Parameter batch: Array of payslip items to process
    /// - Throws: BatchSaveFailed error with details of failed operations
    private func processBatch(_ batch: [PayslipItem]) async throws {
        var successfulSaves = 0
        var lastError: Error?

        // Migrate items in parallel
        let migratedItems = try await migrationUtilities.migrateItems(batch)

        // Save migrated items in a single transaction
        try modelContext.transaction {
            for payslip in migratedItems {
                modelContext.insert(payslip)
                successfulSaves += 1
            }
        }
        try modelContext.save()

        // If we had partial failures, throw an error with details
        if successfulSaves < batch.count {
            let failedSaves = batch.count - successfulSaves
            throw PayslipRepositoryError.batchSaveFailed(
                successful: successfulSaves,
                failed: failedSaves,
                lastError: lastError
            )
        }
    }

    // MARK: - Batch Deletion

    /// Deletes multiple payslip items in optimized batches
    /// - Parameter payslips: Array of payslip items to delete
    /// - Throws: SwiftData error if batch deletion fails
    func deletePayslips(_ payslips: [PayslipItem]) async throws {
        // Process in batches to avoid memory issues
        for batch in payslips.chunked(into: batchSize) {
            try await processDeletionBatch(batch)
        }
    }

    /// Deletes all payslip items in optimized batches
    /// - Throws: SwiftData error if batch deletion fails
    func deleteAllPayslips() async throws {
        let descriptor = FetchDescriptor<PayslipItem>()
        let items = try modelContext.fetch(descriptor)

        // Process in batches to avoid memory issues
        for batch in items.chunked(into: batchSize) {
            try await processDeletionBatch(batch)
        }
    }

    /// Processes a single batch of payslip items for deletion
    /// - Parameter batch: Array of payslip items to delete
    /// - Throws: SwiftData error if deletion fails
    private func processDeletionBatch(_ batch: [PayslipItem]) async throws {
        try modelContext.transaction {
            for payslip in batch {
                modelContext.delete(payslip)
            }
        }
        try modelContext.save()
    }
}

// MARK: - Array Extension for Chunking

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
