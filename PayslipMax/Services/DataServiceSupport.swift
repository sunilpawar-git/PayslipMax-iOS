import Foundation
import SwiftData

/// Support component for DataService containing utility methods and helper functions.
/// This class provides common functionality used across the data service components,
/// maintaining separation of concerns while providing reusable utilities.
///
/// Key Responsibilities:
/// - Context management utilities (processPendingChanges)
/// - Data validation helpers
/// - Performance monitoring utilities
/// - Logging and debugging support
/// - Memory management helpers
/// - Thread-safety utilities for @MainActor operations
@MainActor
final class DataServiceSupport {
    // MARK: - Properties
    private let core: DataServiceCore

    // MARK: - Initialization
    init(core: DataServiceCore) {
        self.core = core
    }

    // MARK: - Context Management Utilities
    /// Process any pending changes in the model context.
    /// This helps flush operations and ensure the database state is consistent.
    /// Useful for ensuring data integrity before critical operations.
    func processPendingChanges() {
        core.modelContext.processPendingChanges()
    }

    // MARK: - Validation Helpers
    /// Validates that the service supports the given type.
    /// - Parameter type: The type to validate
    /// - Returns: True if the type is supported (currently only PayslipItem)
    func isSupportedType<T>(_ type: T.Type) -> Bool where T: Identifiable {
        return type == PayslipItem.self
    }

    /// Validates that a collection of items is non-empty and of supported type.
    /// - Parameter items: The items to validate
    /// - Returns: True if valid, false otherwise
    func isValidBatch<T>(_ items: [T]) -> Bool where T: Identifiable {
        return !items.isEmpty && items.allSatisfy { $0 is PayslipItem }
    }

    // MARK: - Performance Monitoring
    /// Monitors the performance of a data operation.
    /// - Parameters:
    ///   - operation: The operation name for logging
    ///   - operation: The async operation to monitor
    /// - Returns: The result of the operation
    /// - Throws: Any error thrown by the operation
    func monitorPerformance<T>(
        operation: String,
        _ block: () async throws -> T
    ) async throws -> T {
        let startTime = Date()

        do {
            let result = try await block()
            let duration = Date().timeIntervalSince(startTime)

            #if DEBUG
            print("DataService: \(operation) completed in \(String(format: "%.3f", duration))s")
            #endif

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)

            #if DEBUG
            print("DataService: \(operation) failed after \(String(format: "%.3f", duration))s - Error: \(error.localizedDescription)")
            #endif

            throw error
        }
    }

    // MARK: - Memory Management
    /// Performs cleanup operations to free memory.
    /// Useful after large batch operations or when memory pressure is detected.
    func performCleanup() {
        // Process any pending changes to free up memory
        processPendingChanges()

        // Force garbage collection hint (SwiftData specific optimizations)
        // Note: This is a hint to the system, not a guarantee
        core.modelContext.processPendingChanges()
    }

    // MARK: - Logging Utilities
    /// Logs data service operations for debugging and monitoring.
    /// - Parameters:
    ///   - operation: The operation being performed
    ///   - details: Additional context or details
    ///   - level: The log level (debug, info, warning, error)
    func logOperation(_ operation: String, details: String? = nil, level: LogLevel = .info) {
        let timestamp = Date().formatted(.dateTime.hour().minute().second())
        let prefix = "[\(timestamp)] DataService"

        let message = details.map { "\(prefix): \(operation) - \($0)" } ?? "\(prefix): \(operation)"

        switch level {
        case .debug:
            #if DEBUG
            print("🔍 \(message)")
            #endif
        case .info:
            print("ℹ️ \(message)")
        case .warning:
            print("⚠️ \(message)")
        case .error:
            print("❌ \(message)")
        case .critical:
            print("🚨 \(message)")
        }
    }

    // MARK: - Data Integrity Helpers
    /// Verifies data integrity after operations.
    /// - Parameter items: Items to verify
    /// - Returns: True if all items appear valid
    func verifyDataIntegrity<T>(_ items: [T]) -> Bool where T: Identifiable {
        // Basic integrity checks
        return !items.isEmpty && items.allSatisfy { item in
            // Check that items have valid IDs
            if let payslip = item as? PayslipItem {
                return !payslip.id.uuidString.isEmpty
            }
            return false
        }
    }

    // MARK: - Batch Processing Helpers
    /// Calculates optimal batch size for operations based on available memory.
    /// - Parameter totalItems: Total number of items to process
    /// - Returns: Recommended batch size
    func calculateOptimalBatchSize(totalItems: Int) -> Int {
        // Start with a reasonable default
        var batchSize = 100

        // Adjust based on total items
        if totalItems < 100 {
            batchSize = totalItems
        } else if totalItems > 1000 {
            batchSize = 500 // Larger batches for very large datasets
        }

        // Could be enhanced with actual memory monitoring
        // For now, return the calculated size
        return batchSize
    }
}

// MARK: - Supporting Types
/// Note: LogLevel enum is defined in Core/Utilities/Logger.swift
/// This file uses the existing LogLevel enum from the Logger utility.

/// Performance metrics for data operations
struct DataOperationMetrics {
    let operation: String
    let startTime: Date
    let itemCount: Int
    let success: Bool

    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    var itemsPerSecond: Double {
        guard duration > 0 else { return 0 }
        return Double(itemCount) / duration
    }
}
