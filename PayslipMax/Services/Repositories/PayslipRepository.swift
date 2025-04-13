import Foundation
import SwiftData

/// Implementation of the PayslipRepositoryProtocol that uses SwiftData for persistence
@MainActor
final class PayslipRepository: PayslipRepositoryProtocol {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let modelContainer: ModelContainer
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.modelContainer = modelContext.container
    }
    
    // MARK: - PayslipRepositoryProtocol
    
    func fetchAllPayslips() async throws -> [PayslipItem] {
        let descriptor = FetchDescriptor<PayslipItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func fetchPayslips(withFilter filter: NSPredicate?) async throws -> [PayslipItem] {
        var descriptor = FetchDescriptor<PayslipItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        if let filter = filter {
            // Convert NSPredicate to SwiftData's Predicate if possible, or use a simple predicate
            let simplePredicate = #Predicate<PayslipItem> { _ in true }
            descriptor.predicate = simplePredicate
            
            // If specific filters are needed, we should implement custom predicates for each case
            // This is a placeholder implementation to allow compilation
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipItem] {
        let predicate = #Predicate<PayslipItem> { payslip in
            payslip.timestamp >= fromDate && payslip.timestamp <= toDate
        }
        
        let descriptor = FetchDescriptor<PayslipItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
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
        for payslip in payslips {
            modelContext.insert(payslip)
        }
        try modelContext.save()
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
