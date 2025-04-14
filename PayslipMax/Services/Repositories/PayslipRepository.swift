import Foundation
import SwiftData

/// Errors that can occur during repository operations
enum PayslipRepositoryError: LocalizedError {
    case batchSaveFailed(successful: Int, failed: Int, lastError: Error?)
    
    var errorDescription: String? {
        switch self {
        case .batchSaveFailed(let successful, let failed, let lastError):
            var description = "Failed to save \(failed) payslips (successfully saved \(successful))"
            if let lastError = lastError {
                description += "\nLast error: \(lastError.localizedDescription)"
            }
            return description
        }
    }
}

/// Implementation of the PayslipRepositoryProtocol that uses SwiftData for persistence
@MainActor
final class PayslipRepository: PayslipRepositoryProtocol {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let modelContainer: ModelContainer
    private let migrationManager: PayslipMigrationManager
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.modelContainer = modelContext.container
        self.migrationManager = PayslipMigrationManager(modelContext: modelContext)
    }
    
    // MARK: - PayslipRepositoryProtocol
    
    func fetchAllPayslips() async throws -> [PayslipItem] {
        let descriptor = FetchDescriptor<PayslipItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let items = try modelContext.fetch(descriptor)
        
        // Perform migrations if needed
        for item in items {
            _ = try await migrationManager.migrateToLatest(item)
        }
        
        return items
    }
    
    func fetchPayslips(withFilter filter: NSPredicate?) async throws -> [PayslipItem] {
        var descriptor = FetchDescriptor<PayslipItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        if let filter = filter {
            // Convert NSPredicate to SwiftData's Predicate
            // For now, we'll implement a basic conversion for common predicates
            if let format = filter.predicateFormat as String? {
                if format.contains("timestamp") {
                    // Example conversion for timestamp-based predicates
                    descriptor.predicate = #Predicate<PayslipItem> { payslip in
                        // Default to true if we can't convert the predicate
                        true
                    }
                }
            }
        }
        
        let items = try modelContext.fetch(descriptor)
        
        // Apply the original NSPredicate as a post-fetch filter if needed
        let filteredItems = filter != nil ? items.filter { filter!.evaluate(with: $0) } : items
        
        // Perform migrations if needed
        for item in filteredItems {
            _ = try await migrationManager.migrateToLatest(item)
        }
        
        return filteredItems
    }
    
    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipItem] {
        let predicate = #Predicate<PayslipItem> { payslip in
            payslip.timestamp >= fromDate && payslip.timestamp <= toDate
        }
        
        let descriptor = FetchDescriptor<PayslipItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let items = try modelContext.fetch(descriptor)
        
        // Perform migrations if needed
        for item in items {
            _ = try await migrationManager.migrateToLatest(item)
        }
        
        return items
    }
    
    func fetchPayslip(byId id: String) async throws -> PayslipItem? {
        // Convert the string ID to a UUID
        guard let uuid = UUID(uuidString: id) else {
            throw NSError(domain: "PayslipRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid UUID format"])
        }
        
        // Use the UUID for comparison
        let predicate = #Predicate<PayslipItem> { payslip in
            payslip.id == uuid
        }
        
        let descriptor = FetchDescriptor<PayslipItem>(predicate: predicate)
        let results = try modelContext.fetch(descriptor)
        return results.first
    }
    
    func savePayslip(_ payslip: PayslipItem) async throws {
        modelContext.insert(payslip)
        try modelContext.save()
    }
    
    func savePayslips(_ payslips: [PayslipItem]) async throws {
        // Validate input
        guard !payslips.isEmpty else { return }
        
        // Track successful saves
        var successfulSaves = 0
        var failedSaves = 0
        var lastError: Error?
        
        // First, migrate all items to the latest schema version
        for payslip in payslips {
            do {
                _ = try await migrationManager.migrateToLatest(payslip)
            } catch {
                failedSaves += 1
                lastError = error
                // Continue with other items even if one fails
            }
        }
        
        // If all migrations failed, throw an error
        if failedSaves == payslips.count {
            throw PayslipRepositoryError.batchSaveFailed(
                successful: 0,
                failed: failedSaves,
                lastError: lastError
            )
        }
        
        // Reset counters for the save operation
        successfulSaves = 0
        failedSaves = 0
        lastError = nil
        
        do {
            // Use a transaction for batch operations
            try modelContext.transaction {
                for payslip in payslips {
                    modelContext.insert(payslip)
                    successfulSaves += 1
                }
            }
            
            // Save all changes at once
            try modelContext.save()
        } catch {
            failedSaves = payslips.count - successfulSaves
            lastError = error
        }
        
        // If any saves failed, throw an error with details
        if failedSaves > 0 {
            throw PayslipRepositoryError.batchSaveFailed(
                successful: successfulSaves,
                failed: failedSaves,
                lastError: lastError
            )
        }
    }
    
    func deletePayslip(_ payslip: PayslipItem) async throws {
        modelContext.delete(payslip)
        try modelContext.save()
    }
    
    func deletePayslips(_ payslips: [PayslipItem]) async throws {
        for payslip in payslips {
            modelContext.delete(payslip)
        }
        try modelContext.save()
    }
    
    func deleteAllPayslips() async throws {
        let payslips = try await fetchAllPayslips()
        
        for payslip in payslips {
            modelContext.delete(payslip)
        }
        
        try modelContext.save()
    }
    
    func countPayslips() async throws -> Int {
        let descriptor = FetchDescriptor<PayslipItem>()
        return try modelContext.fetchCount(descriptor)
    }
} 
