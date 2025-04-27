import Foundation
import SwiftData

/// Represents a detailed payslip record, potentially linking various components.
///
/// This model stores core payslip information along with associated allowances, deductions,
/// and posting details. It is designed to be persisted using SwiftData.
@Model
final class Payslip: Identifiable {
    /// The unique identifier for the payslip record.
    @Attribute(.unique) var id: UUID
    /// The date and time when the payslip was recorded or generated.
    var timestamp: Date
    /// The military rank associated with the payslip.
    var rank: String
    /// The service number associated with the payslip.
    var serviceNumber: String
    /// The basic pay amount for the payslip period.
    var basicPay: Double
    /// An array of `Allowance` items associated with this payslip.
    var allowances: [Allowance]
    /// An array of `Deduction` items associated with this payslip.
    var deductions: [Deduction]
    /// The calculated net pay for the payslip period.
    var netPay: Double
    /// Optional `PostingDetails` associated with this payslip.
    var postingDetails: PostingDetails?
    
    /// Initializes a new payslip record.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - timestamp: Timestamp of the record. Defaults to the current date.
    ///   - rank: The military rank.
    ///   - serviceNumber: The service number.
    ///   - basicPay: The basic pay amount.
    ///   - allowances: Array of allowances. Defaults to empty.
    ///   - deductions: Array of deductions. Defaults to empty.
    ///   - netPay: The calculated net pay.
    ///   - postingDetails: Optional posting details. Defaults to nil.
    init(id: UUID = UUID(), 
         timestamp: Date = Date(),
         rank: String,
         serviceNumber: String,
         basicPay: Double,
         allowances: [Allowance] = [],
         deductions: [Deduction] = [],
         netPay: Double,
         postingDetails: PostingDetails? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.rank = rank
        self.serviceNumber = serviceNumber
        self.basicPay = basicPay
        self.allowances = allowances
        self.deductions = deductions
        self.netPay = netPay
        self.postingDetails = postingDetails
    }
} 