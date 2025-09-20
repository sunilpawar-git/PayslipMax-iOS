import Foundation
import SwiftData

/// Thread-safe actor for Core Data operations on PayslipItem
/// Implements the ModelActor pattern for Swift 6 Sendable compliance
/// Handles all persistence operations safely across async boundaries
@ModelActor
actor PayslipModelActor {

    // MARK: - Fetch Operations

    /// Fetches all payslip items from the persistent store
    /// - Returns: Array of all PayslipItem objects
    /// - Throws: Core Data errors if fetch fails
    func fetchAllPayslips() throws -> [PayslipItem] {
        let descriptor = FetchDescriptor<PayslipItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches payslips within a date range
    /// - Parameters:
    ///   - fromDate: Start date for the range
    ///   - toDate: End date for the range
    /// - Returns: Array of PayslipItem objects within the date range
    /// - Throws: Core Data errors if fetch fails
    func fetchPayslips(fromDate: Date, toDate: Date) throws -> [PayslipItem] {
        let predicate = #Predicate<PayslipItem> { payslip in
            payslip.timestamp >= fromDate && payslip.timestamp <= toDate
        }
        let descriptor = FetchDescriptor<PayslipItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches a specific payslip by its ID
    /// - Parameter id: The UUID of the payslip to fetch
    /// - Returns: The PayslipItem if found, nil otherwise
    /// - Throws: Core Data errors if fetch fails
    func fetchPayslip(byId id: UUID) throws -> PayslipItem? {
        let predicate = #Predicate<PayslipItem> { payslip in
            payslip.id == id
        }
        let descriptor = FetchDescriptor<PayslipItem>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    /// Fetches payslips for a specific month and year
    /// - Parameters:
    ///   - month: The month to search for
    ///   - year: The year to search for
    /// - Returns: Array of PayslipItem objects for the specified period
    /// - Throws: Core Data errors if fetch fails
    func fetchPayslips(forMonth month: String, year: Int) throws -> [PayslipItem] {
        let predicate = #Predicate<PayslipItem> { payslip in
            payslip.month == month && payslip.year == year
        }
        let descriptor = FetchDescriptor<PayslipItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Save Operations

    /// Saves a new payslip to the persistent store
    /// - Parameter payslip: The PayslipItem to save
    /// - Throws: Core Data errors if save fails
    func savePayslip(_ payslip: PayslipItem) throws {
        modelContext.insert(payslip)
        try modelContext.save()
    }

    /// Saves multiple payslips in a batch operation
    /// - Parameter payslips: Array of PayslipItem objects to save
    /// - Throws: Core Data errors if save fails
    func savePayslips(_ payslips: [PayslipItem]) throws {
        for payslip in payslips {
            modelContext.insert(payslip)
        }
        try modelContext.save()
    }

    /// Creates and saves a payslip from DTO data
    /// - Parameter dto: The PayslipDTO containing the data
    /// - Returns: The created PayslipItem
    /// - Throws: Core Data errors if save fails
    func createPayslip(from dto: PayslipDTO) throws -> PayslipItem {
        let payslip = PayslipItem(
            id: dto.id,
            timestamp: dto.timestamp,
            month: dto.month,
            year: dto.year,
            credits: dto.credits,
            debits: dto.debits
        )
        payslip.updateFrom(dto)

        modelContext.insert(payslip)
        try modelContext.save()

        return payslip
    }

    // MARK: - Update Operations

    /// Updates an existing payslip with new data
    /// - Parameters:
    ///   - id: The ID of the payslip to update
    ///   - dto: The PayslipDTO containing updated data
    /// - Returns: The updated PayslipItem if found, nil otherwise
    /// - Throws: Core Data errors if save fails
    func updatePayslip(withId id: UUID, from dto: PayslipDTO) throws -> PayslipItem? {
        guard let existingPayslip = try fetchPayslip(byId: id) else {
            return nil
        }

        existingPayslip.updateFrom(dto)
        try modelContext.save()

        return existingPayslip
    }

    // MARK: - Delete Operations

    /// Deletes a payslip by its ID
    /// - Parameter id: The UUID of the payslip to delete
    /// - Returns: True if the payslip was deleted, false if not found
    /// - Throws: Core Data errors if delete fails
    func deletePayslip(withId id: UUID) throws -> Bool {
        guard let payslip = try fetchPayslip(byId: id) else {
            return false
        }

        modelContext.delete(payslip)
        try modelContext.save()

        return true
    }

    /// Deletes multiple payslips by their IDs
    /// - Parameter ids: Array of UUIDs of payslips to delete
    /// - Returns: Number of payslips successfully deleted
    /// - Throws: Core Data errors if delete fails
    func deletePayslips(withIds ids: [UUID]) throws -> Int {
        var deletedCount = 0

        for id in ids {
            if let payslip = try fetchPayslip(byId: id) {
                modelContext.delete(payslip)
                deletedCount += 1
            }
        }

        try modelContext.save()
        return deletedCount
    }

    /// Deletes all payslips from the persistent store
    /// - Returns: Number of payslips deleted
    /// - Throws: Core Data errors if delete fails
    func deleteAllPayslips() throws -> Int {
        let allPayslips = try fetchAllPayslips()
        let count = allPayslips.count

        for payslip in allPayslips {
            modelContext.delete(payslip)
        }

        try modelContext.save()
        return count
    }

    // MARK: - Utility Operations

    /// Counts the total number of payslips
    /// - Returns: The total count of payslips
    /// - Throws: Core Data errors if fetch fails
    func countPayslips() throws -> Int {
        let descriptor = FetchDescriptor<PayslipItem>()
        return try modelContext.fetchCount(descriptor)
    }

    /// Checks if a payslip exists with the given ID
    /// - Parameter id: The UUID to check for
    /// - Returns: True if the payslip exists, false otherwise
    /// - Throws: Core Data errors if fetch fails
    func payslipExists(withId id: UUID) throws -> Bool {
        return try fetchPayslip(byId: id) != nil
    }
}

// MARK: - Sendable Repository Protocol

/// Protocol for Sendable payslip repository operations
/// Exposes thread-safe async operations using DTOs
protocol SendablePayslipRepository: Sendable {
    func fetchAllPayslips() async throws -> [PayslipDTO]
    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipDTO]
    func fetchPayslip(byId id: UUID) async throws -> PayslipDTO?
    func savePayslip(_ dto: PayslipDTO) async throws -> UUID
    func updatePayslip(withId id: UUID, from dto: PayslipDTO) async throws -> Bool
    func deletePayslip(withId id: UUID) async throws -> Bool
    func countPayslips() async throws -> Int
}
