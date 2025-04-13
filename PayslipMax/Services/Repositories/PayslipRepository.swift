import Foundation
import SwiftData

/// Implementation of the PayslipRepository that uses SwiftData for persistence
final class PayslipRepository: PayslipRepositoryProtocol {
    // MARK: - Properties
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - PayslipRepositoryProtocol
    
    func fetchAllPayslips() async throws -> [PayslipItem] {
        let descriptor = FetchDescriptor<PayslipItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func fetchPayslips(withFilter filter: NSPredicate?) async throws -> [PayslipItem] {
        // Create a descriptor with sorting
        let descriptor = FetchDescriptor<PayslipItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        // Convert NSPredicate to SwiftData Predicate if provided
        if let filter = filter {
            // For simple compatibility, we'll fetch all and filter in memory
            // This is a transitional approach until we fully migrate to modern predicates
            let allPayslips = try modelContext.fetch(descriptor)
            return allPayslips.filter { payslip in
                filter.evaluate(with: payslip)
            }
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipItem] {
        let predicate = #Predicate<PayslipItem> { payslip in
            payslip.timestamp >= fromDate && payslip.timestamp <= toDate
        }
        var descriptor = FetchDescriptor<PayslipItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        descriptor.predicate = predicate
        return try modelContext.fetch(descriptor)
    }
    
    func fetchPayslip(byId id: String) async throws -> PayslipItem? {
        let predicate = #Predicate<PayslipItem> { payslip in
            payslip.id.uuidString == id
        }
        var descriptor = FetchDescriptor<PayslipItem>()
        descriptor.predicate = predicate
        descriptor.fetchLimit = 1
        
        let results = try modelContext.fetch(descriptor)
        return results.first
    }
    
    func savePayslip(_ payslip: PayslipItem) async throws {
        modelContext.insert(payslip)
        try modelContext.save()
    }
    
    func deletePayslip(_ payslip: PayslipItem) async throws {
        modelContext.delete(payslip)
        try modelContext.save()
    }
    
    func deleteAllPayslips() async throws {
        let descriptor = FetchDescriptor<PayslipItem>()
        let items = try modelContext.fetch(descriptor)
        
        for item in items {
            modelContext.delete(item)
        }
        
        try modelContext.save()
    }
    
    func countPayslips() async throws -> Int {
        let descriptor = FetchDescriptor<PayslipItem>()
        return try modelContext.fetchCount(descriptor)
    }
} 
