import Foundation

struct LLMPayslipResponse: Decodable {
    let earnings: [String: Double]?
    let deductions: [String: Double]?
    let grossPay: Double?
    let totalDeductions: Double?
    let netRemittance: Double?
    let month: String?
    let year: Int?

    /// Memberwise initializer for testing and manual construction
    init(
        earnings: [String: Double]? = nil,
        deductions: [String: Double]? = nil,
        grossPay: Double? = nil,
        totalDeductions: Double? = nil,
        netRemittance: Double? = nil,
        month: String? = nil,
        year: Int? = nil
    ) {
        self.earnings = earnings
        self.deductions = deductions
        self.grossPay = grossPay
        self.totalDeductions = totalDeductions
        self.netRemittance = netRemittance
        self.month = month
        self.year = year
    }
}


