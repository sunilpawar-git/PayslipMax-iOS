import Foundation
import SwiftData

@Model
final class Payslip: Identifiable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var rank: String
    var serviceNumber: String
    var basicPay: Double
    var allowances: [Allowance]
    var deductions: [Deduction]
    var netPay: Double
    var postingDetails: PostingDetails?
    
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