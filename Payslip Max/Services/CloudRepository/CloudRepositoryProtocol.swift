import Foundation
import SwiftData

// Forward declaration for PayslipItem
@objc protocol PayslipItemProtocol {}
extension PayslipItem: PayslipItemProtocol {}

protocol CloudRepositoryProtocol {
    func syncPayslips(_ payslips: [PayslipItem]) async throws
    func backupPayslips(_ payslips: [PayslipItem]) async throws -> URL
    func fetchBackups() async throws -> [PayslipBackup]
    func restoreFromBackup(_ backupId: String) async throws -> [PayslipItem]
}

// Create a simple backup model
struct PayslipBackup: Identifiable, Codable {
    let id: String
    let createdAt: Date
    let payslipCount: Int
    let size: Int
    let name: String
} 