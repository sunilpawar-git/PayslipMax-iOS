import Foundation
import SwiftData

/// Utility class for building SwiftData queries for PayslipItem
/// Centralizes query creation and configuration logic
/// Follows SOLID principles with single responsibility focus
@MainActor
final class PayslipQueryBuilder {

    // MARK: - Query Building

    /// Creates a fetch descriptor for all payslips sorted by timestamp
    /// - Returns: Configured FetchDescriptor for all payslips
    static func fetchAllDescriptor() -> FetchDescriptor<PayslipItem> {
        FetchDescriptor<PayslipItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
    }

    /// Creates a fetch descriptor for payslips with optional filter
    /// - Parameter filter: Optional predicate to filter results
    /// - Returns: Configured FetchDescriptor with filter applied
    static func fetchWithFilterDescriptor(filter: Predicate<PayslipItem>?) -> FetchDescriptor<PayslipItem> {
        var descriptor = FetchDescriptor<PayslipItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        if let filter = filter {
            descriptor.predicate = filter
        }

        return descriptor
    }

    /// Creates a fetch descriptor for payslips within a date range
    /// - Parameters:
    ///   - fromDate: Start date for the range
    ///   - toDate: End date for the range
    /// - Returns: Configured FetchDescriptor for date range
    static func fetchDateRangeDescriptor(fromDate: Date, toDate: Date) -> FetchDescriptor<PayslipItem> {
        let predicate = #Predicate<PayslipItem> { payslip in
            payslip.timestamp >= fromDate && payslip.timestamp <= toDate
        }

        return FetchDescriptor<PayslipItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
    }

    /// Creates a fetch descriptor for a specific payslip by ID
    /// - Parameter uuid: UUID of the payslip to fetch
    /// - Returns: Configured FetchDescriptor for single payslip
    static func fetchByIdDescriptor(uuid: UUID) -> FetchDescriptor<PayslipItem> {
        let predicate = #Predicate<PayslipItem> { $0.id == uuid }

        return FetchDescriptor<PayslipItem>(predicate: predicate)
    }

    /// Creates a fetch descriptor for paginated results
    /// - Parameters:
    ///   - page: Page number (0-based)
    ///   - pageSize: Number of items per page
    ///   - filter: Optional predicate to filter results
    ///   - sortBy: KeyPath to sort by
    ///   - ascending: Sort direction
    /// - Returns: Configured FetchDescriptor for pagination
    static func fetchPaginatedDescriptor(
        page: Int,
        pageSize: Int,
        filter: Predicate<PayslipItem>?,
        sortBy: KeyPath<PayslipItem, some Comparable>,
        ascending: Bool
    ) -> FetchDescriptor<PayslipItem> {
        var descriptor = FetchDescriptor<PayslipItem>()

        if let filter = filter {
            descriptor.predicate = filter
        }

        // Configure pagination
        descriptor.fetchOffset = page * pageSize
        descriptor.fetchLimit = pageSize

        // Configure sorting
        descriptor.sortBy = [SortDescriptor(sortBy, order: ascending ? .forward : .reverse)]

        return descriptor
    }

    /// Creates a fetch descriptor for counting items
    /// - Parameter filter: Optional predicate to filter results
    /// - Returns: Configured FetchDescriptor for counting
    static func fetchCountDescriptor(filter: Predicate<PayslipItem>? = nil) -> FetchDescriptor<PayslipItem> {
        var descriptor = FetchDescriptor<PayslipItem>()

        if let filter = filter {
            descriptor.predicate = filter
        }

        return descriptor
    }
}
