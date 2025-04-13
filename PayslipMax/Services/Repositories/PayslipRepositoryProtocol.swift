import Foundation

/// Protocol that defines operations specific to payslip data management.
/// This repository pattern provides a clear abstraction layer for payslip data operations.
@MainActor protocol PayslipRepositoryProtocol {
    /// Fetches all payslips
    func fetchAllPayslips() async throws -> [PayslipItem]
    
    /// Fetches payslips matching the given criteria
    func fetchPayslips(withFilter filter: NSPredicate?) async throws -> [PayslipItem]
    
    /// Fetches payslips within a specific date range
    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipItem]
    
    /// Fetches a specific payslip by its ID
    func fetchPayslip(byId id: String) async throws -> PayslipItem?
    
    /// Saves a payslip to the persistent store
    func savePayslip(_ payslip: PayslipItem) async throws
    
    /// Deletes a payslip from the persistent store
    func deletePayslip(_ payslip: PayslipItem) async throws
    
    /// Deletes all payslips
    func deleteAllPayslips() async throws
    
    /// Counts the number of payslips in the repository
    func countPayslips() async throws -> Int
} 