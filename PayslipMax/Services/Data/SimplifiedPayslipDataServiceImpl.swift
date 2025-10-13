import Foundation
import SwiftData

/// Implementation of SimplifiedPayslipDataService using SwiftData
@MainActor
class SimplifiedPayslipDataServiceImpl: SimplifiedPayslipDataService {

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - SimplifiedPayslipDataService Implementation

    func save(_ payslip: SimplifiedPayslip) async throws {
        modelContext.insert(payslip)
        try modelContext.save()
    }

    func fetchAll() async -> [SimplifiedPayslip] {
        let descriptor = FetchDescriptor<SimplifiedPayslip>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching simplified payslips: \(error)")
            return []
        }
    }

    func delete(_ payslip: SimplifiedPayslip) async throws {
        modelContext.delete(payslip)
        try modelContext.save()
    }
}

