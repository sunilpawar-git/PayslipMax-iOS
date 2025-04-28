import Foundation

/// Protocol that defines operations specific to payslip data management.
/// 
/// This repository pattern provides a clear abstraction layer for payslip data operations,
/// decoupling the business logic from the underlying persistence mechanism. Implementations
/// of this protocol handle the details of storing, retrieving, and managing payslip data
/// while providing a consistent interface to the rest of the application.
///
/// All methods in this protocol are marked with @MainActor to ensure they're called
/// from the main thread, which is required for SwiftData operations.
@MainActor protocol PayslipRepositoryProtocol {
    /// Fetches all payslips from the repository.
    ///
    /// Retrieves all stored payslips ordered by timestamp (most recent first).
    ///
    /// - Returns: An array of all stored PayslipItem objects.
    /// - Throws: Repository errors if fetching fails or if migration is needed but fails.
    func fetchAllPayslips() async throws -> [PayslipItem]
    
    /// Fetches payslips matching the given criteria.
    ///
    /// Allows filtering payslips based on a predicate to retrieve specific subsets of data.
    ///
    /// - Parameter filter: An optional NSPredicate specifying the filter criteria.
    ///                     If nil, all payslips are returned.
    /// - Returns: An array of PayslipItem objects matching the filter criteria.
    /// - Throws: Repository errors if predicate conversion fails, fetching fails, or migration fails.
    func fetchPayslips(withFilter filter: NSPredicate?) async throws -> [PayslipItem]
    
    /// Fetches payslips within a specific date range.
    ///
    /// Retrieves payslips with timestamps between the specified dates, inclusive.
    ///
    /// - Parameters:
    ///   - fromDate: The start date of the range (inclusive).
    ///   - toDate: The end date of the range (inclusive).
    /// - Returns: An array of PayslipItem objects with timestamps within the specified range.
    /// - Throws: Repository errors if date filtering or fetching fails.
    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipItem]
    
    /// Fetches a specific payslip by its ID.
    ///
    /// Retrieves a single payslip with the specified unique identifier.
    ///
    /// - Parameter id: The unique identifier (UUID string) of the payslip to fetch.
    /// - Returns: The matching PayslipItem if found, or nil if no payslip with the specified ID exists.
    /// - Throws: Repository errors if the ID format is invalid or if fetching fails.
    func fetchPayslip(byId id: String) async throws -> PayslipItem?
    
    /// Saves a payslip to the persistent store.
    ///
    /// Stores a new payslip or updates an existing one if it has the same ID.
    /// Performs schema migration if needed before saving.
    ///
    /// - Parameter payslip: The PayslipItem to save.
    /// - Throws: Repository errors if migration fails or if saving fails.
    func savePayslip(_ payslip: PayslipItem) async throws
    
    /// Saves multiple payslips in a single batch operation.
    ///
    /// Efficiently stores multiple payslips, processing them in appropriate batch sizes
    /// to optimize performance and memory usage.
    ///
    /// - Parameter payslips: An array of PayslipItem objects to save.
    /// - Throws: Repository errors including batch processing failures or migration errors.
    func savePayslips(_ payslips: [PayslipItem]) async throws
    
    /// Deletes a payslip from the persistent store.
    ///
    /// Removes a specific payslip from storage.
    ///
    /// - Parameter payslip: The PayslipItem to delete.
    /// - Throws: Repository errors if deletion fails.
    func deletePayslip(_ payslip: PayslipItem) async throws
    
    /// Deletes multiple payslips in a single batch operation.
    ///
    /// Efficiently removes multiple payslips, processing them in appropriate batch sizes
    /// to optimize performance and memory usage.
    ///
    /// - Parameter payslips: An array of PayslipItem objects to delete.
    /// - Throws: Repository errors including batch deletion failures.
    func deletePayslips(_ payslips: [PayslipItem]) async throws
    
    /// Deletes all payslips from the repository.
    ///
    /// Removes all stored payslips. This operation is processed in batches to avoid
    /// memory issues with large datasets.
    ///
    /// - Throws: Repository errors if the deletion process fails.
    func deleteAllPayslips() async throws
    
    /// Counts the number of payslips in the repository.
    ///
    /// Efficiently determines the total number of stored payslips without loading the actual objects.
    ///
    /// - Returns: The count of payslips in the repository.
    /// - Throws: Repository errors if the count operation fails.
    func countPayslips() async throws -> Int
} 