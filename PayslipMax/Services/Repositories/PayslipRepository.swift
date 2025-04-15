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
@MainActor
final class PayslipRepository: PayslipRepositoryProtocol {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let modelContainer: ModelContainer
    private let migrationManager: PayslipMigrationManager
    
    // MARK: - Constants
    
    private let batchSize = 50 // Optimal batch size for operations
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.modelContainer = modelContext.container
        self.migrationManager = PayslipMigrationManager(modelContext: modelContext)
    }
    
    // MARK: - PayslipRepositoryProtocol
    
    func fetchAllPayslips() async throws -> [PayslipItem] {
        let descriptor = FetchDescriptor<PayslipItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let items = try modelContext.fetch(descriptor)
        return try await migrateItemsIfNeeded(items)
    }
    
    func fetchPayslips(withFilter filter: NSPredicate?) async throws -> [PayslipItem] {
        var descriptor = FetchDescriptor<PayslipItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        if let filter = filter {
            descriptor.predicate = try convertNSPredicateToPredicate(filter)
        }
        
        let items = try modelContext.fetch(descriptor)
        return try await migrateItemsIfNeeded(items)
    }
    
    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipItem] {
        let predicate = #Predicate<PayslipItem> { payslip in
            payslip.timestamp >= fromDate && payslip.timestamp <= toDate
        }
        
        let descriptor = FetchDescriptor<PayslipItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let items = try modelContext.fetch(descriptor)
            return try await migrateItemsIfNeeded(items)
        } catch {
            throw PayslipRepositoryError.queryFailed(error)
        }
    }
    
    func fetchPayslip(byId id: String) async throws -> PayslipItem? {
        guard let uuid = UUID(uuidString: id) else {
            throw PayslipRepositoryError.invalidUUIDFormat
        }
        
        let descriptor = FetchDescriptor<PayslipItem>(
            predicate: #Predicate<PayslipItem> { $0.id == uuid }
        )
        let items = try modelContext.fetch(descriptor)
        return try await migrateItemsIfNeeded(items).first
    }
    
    func savePayslip(_ payslip: PayslipItem) async throws {
        do {
            _ = try await migrationManager.migrateToLatest(payslip)
            modelContext.insert(payslip)
            try modelContext.save()
        } catch {
            throw PayslipRepositoryError.migrationFailed(error)
        }
    }
    
    func savePayslips(_ payslips: [PayslipItem]) async throws {
        guard !payslips.isEmpty else { return }
        
        // Process in batches to avoid memory issues
        for batch in payslips.chunked(into: batchSize) {
            try await processBatch(batch)
        }
    }
    
    func deletePayslip(_ payslip: PayslipItem) async throws {
        modelContext.delete(payslip)
        try modelContext.save()
    }
    
    func deletePayslips(_ payslips: [PayslipItem]) async throws {
        // Process in batches to avoid memory issues
        for batch in payslips.chunked(into: batchSize) {
            try await processDeletionBatch(batch)
        }
    }
    
    func deleteAllPayslips() async throws {
        let descriptor = FetchDescriptor<PayslipItem>()
        let items = try modelContext.fetch(descriptor)
        
        // Process in batches to avoid memory issues
        for batch in items.chunked(into: batchSize) {
            try await processDeletionBatch(batch)
        }
    }
    
    func countPayslips() async throws -> Int {
        let descriptor = FetchDescriptor<PayslipItem>()
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
        var descriptor = FetchDescriptor<PayslipItem>()
        
        if let filter = filter {
            descriptor.predicate = try convertNSPredicateToPredicate(filter)
        }
        
        // Get total count first
        let totalCount = try modelContext.fetchCount(descriptor)
        
        // Configure pagination
        descriptor.fetchOffset = page * pageSize
        descriptor.fetchLimit = pageSize
        
        // Add sorting
        descriptor.sortBy = [SortDescriptor(sortBy, order: ascending ? .forward : .reverse)]
        
        // Fetch items
        let items = try modelContext.fetch(descriptor)
        return (try await migrateItemsIfNeeded(items), totalCount)
    }
    
    // MARK: - Helper Methods
    
    private func convertNSPredicateToPredicate(_ nsPredicate: NSPredicate) throws -> Predicate<PayslipItem> {
        if let comparisonPredicate = nsPredicate as? NSComparisonPredicate {
            return try convertComparisonPredicate(comparisonPredicate)
        } else if let compoundPredicate = nsPredicate as? NSCompoundPredicate {
            return try convertCompoundPredicate(compoundPredicate)
        }
        throw PayslipRepositoryError.invalidPredicate
    }
    
    private func convertComparisonPredicate(_ predicate: NSComparisonPredicate) throws -> Predicate<PayslipItem> {
        let keyPathString = predicate.leftExpression.keyPath
        let value = predicate.rightExpression.constantValue
        
        switch (keyPathString, predicate.predicateOperatorType) {
        case ("timestamp", .equalTo):
            if let date = value as? Date {
                return #Predicate<PayslipItem> { $0.timestamp == date }
            }
        case ("timestamp", .greaterThan):
            if let date = value as? Date {
                return #Predicate<PayslipItem> { $0.timestamp > date }
            }
        case ("timestamp", .lessThan):
            if let date = value as? Date {
                return #Predicate<PayslipItem> { $0.timestamp < date }
            }
        case ("schemaVersion", .equalTo):
            if let version = value as? PayslipSchemaVersion {
                let versionValue = version.rawValue
                return #Predicate<PayslipItem> { $0.schemaVersion == versionValue }
            }
        case ("id", .equalTo):
            if let uuid = value as? UUID {
                return #Predicate<PayslipItem> { $0.id == uuid }
            }
        default:
            break
        }
        
        throw PayslipRepositoryError.unsupportedPredicateOperator
    }
    
    private func convertCompoundPredicate(_ predicate: NSCompoundPredicate) throws -> Predicate<PayslipItem> {
        let subpredicates = try predicate.subpredicates.map { subpredicate in
            guard let nsPredicate = subpredicate as? NSPredicate else {
                throw PayslipRepositoryError.invalidPredicate
            }
            return try convertNSPredicateToPredicate(nsPredicate)
        }
        
        guard let first = subpredicates.first else {
            throw PayslipRepositoryError.invalidPredicate
        }
        
        switch predicate.compoundPredicateType {
        case .and:
            return subpredicates.dropFirst().reduce(first) { result, next in
                #Predicate<PayslipItem> { item in
                    result.evaluate(item) && next.evaluate(item)
                }
            }
        case .or:
            return subpredicates.dropFirst().reduce(first) { result, next in
                #Predicate<PayslipItem> { item in
                    result.evaluate(item) || next.evaluate(item)
                }
            }
        case .not:
            return #Predicate<PayslipItem> { item in
                !first.evaluate(item)
            }
        @unknown default:
            throw PayslipRepositoryError.unsupportedPredicateOperator
        }
    }
    
    // MARK: - Private Methods
    
    private func migrateItemsIfNeeded(_ items: [PayslipItem]) async throws -> [PayslipItem] {
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
    
    private func processBatch(_ batch: [PayslipItem]) async throws {
        var successfulSaves = 0
        var failedSaves = 0
        var lastError: Error?
        
        // Migrate items in parallel
        async let migrations = batch.concurrentMap { [self] payslip in
            try await migrationManager.migrateToLatest(payslip)
        }
        
        do {
            let migratedItems = try await migrations
            
            // Save migrated items in a single transaction
            try modelContext.transaction {
                for payslip in migratedItems {
                    modelContext.insert(payslip)
                    successfulSaves += 1
                }
            }
            try modelContext.save()
        } catch {
            failedSaves = batch.count - successfulSaves
            lastError = error
            
            if failedSaves == batch.count {
                throw PayslipRepositoryError.batchSaveFailed(
                    successful: successfulSaves,
                    failed: failedSaves,
                    lastError: lastError
                )
            }
        }
    }
    
    private func processDeletionBatch(_ batch: [PayslipItem]) async throws {
        try modelContext.transaction {
            for payslip in batch {
                modelContext.delete(payslip)
            }
        }
        try modelContext.save()
    }
}

// MARK: - Array Extension

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
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
