import Foundation
import SwiftData

/// Sendable repository implementation using PayslipModelActor
/// Provides thread-safe access to payslip data through async/await
/// All operations use PayslipDTO for Sendable compliance
final class SendablePayslipRepositoryImpl: SendablePayslipRepository {
    private let modelContainer: ModelContainer

    // MARK: - Initialization

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Fetch Operations

    func fetchAllPayslips() async throws -> [PayslipDTO] {
        let modelActor = PayslipModelActor(modelContainer: modelContainer)
        let payslips = try await modelActor.fetchAllPayslips()
        return payslips.map { PayslipDTO(from: $0) }
    }

    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipDTO] {
        let modelActor = PayslipModelActor(modelContainer: modelContainer)
        let payslips = try await modelActor.fetchPayslips(fromDate: fromDate, toDate: toDate)
        return payslips.map { PayslipDTO(from: $0) }
    }

    func fetchPayslip(byId id: UUID) async throws -> PayslipDTO? {
        let modelActor = PayslipModelActor(modelContainer: modelContainer)
        guard let payslip = try await modelActor.fetchPayslip(byId: id) else {
            return nil
        }
        return PayslipDTO(from: payslip)
    }

    // MARK: - Save Operations

    func savePayslip(_ dto: PayslipDTO) async throws -> UUID {
        let modelActor = PayslipModelActor(modelContainer: modelContainer)
        let payslip = try await modelActor.createPayslip(from: dto)
        return payslip.id
    }

    // MARK: - Update Operations

    func updatePayslip(withId id: UUID, from dto: PayslipDTO) async throws -> Bool {
        let modelActor = PayslipModelActor(modelContainer: modelContainer)
        let updatedPayslip = try await modelActor.updatePayslip(withId: id, from: dto)
        return updatedPayslip != nil
    }

    // MARK: - Delete Operations

    func deletePayslip(withId id: UUID) async throws -> Bool {
        let modelActor = PayslipModelActor(modelContainer: modelContainer)
        return try await modelActor.deletePayslip(withId: id)
    }

    // MARK: - Utility Operations

    func countPayslips() async throws -> Int {
        let modelActor = PayslipModelActor(modelContainer: modelContainer)
        return try await modelActor.countPayslips()
    }
}

// Note: PayslipRepositoryError is defined in PayslipRepository.swift

// MARK: - DI Container Integration

extension DIContainer {
    /// Creates a SendablePayslipRepository instance
    func makeSendablePayslipRepository() -> SendablePayslipRepository {
        // Use the shared model container from AppContainer
        guard let modelContainer = AppContainer.shared.resolve(ModelContainer.self) else {
            fatalError("ModelContainer not registered in AppContainer")
        }
        return SendablePayslipRepositoryImpl(modelContainer: modelContainer)
    }
}

// MARK: - Batch Operations Extension

extension SendablePayslipRepositoryImpl {
    /// Saves multiple payslips in a batch operation
    /// - Parameter dtos: Array of PayslipDTO objects to save
    /// - Returns: Array of UUIDs for the saved payslips
    /// - Throws: Repository errors if batch save fails
    func savePayslips(_ dtos: [PayslipDTO]) async throws -> [UUID] {
        let modelActor = PayslipModelActor(modelContainer: modelContainer)
        var savedIds: [UUID] = []

        // Process in batches to avoid memory issues
        let batchSize = 50
        for batch in dtos.chunked(into: batchSize) {
            for dto in batch {
                let payslip = try await modelActor.createPayslip(from: dto)
                savedIds.append(payslip.id)
            }
        }

        return savedIds
    }

    /// Deletes multiple payslips by their IDs
    /// - Parameter ids: Array of UUIDs of payslips to delete
    /// - Returns: Number of payslips successfully deleted
    /// - Throws: Repository errors if batch delete fails
    func deletePayslips(withIds ids: [UUID]) async throws -> Int {
        let modelActor = PayslipModelActor(modelContainer: modelContainer)
        return try await modelActor.deletePayslips(withIds: ids)
    }

    /// Fetches payslips for a specific month and year
    /// - Parameters:
    ///   - month: The month to search for
    ///   - year: The year to search for
    /// - Returns: Array of PayslipDTO objects for the specified period
    /// - Throws: Repository errors if fetch fails
    func fetchPayslips(forMonth month: String, year: Int) async throws -> [PayslipDTO] {
        let modelActor = PayslipModelActor(modelContainer: modelContainer)
        let payslips = try await modelActor.fetchPayslips(forMonth: month, year: year)
        return payslips.map { PayslipDTO(from: $0) }
    }
}

// MARK: - Array Extension for Batching

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
