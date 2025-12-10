import Foundation

struct LLMPayslipResponse: Decodable {
    let earnings: [String: Double]?
    let deductions: [String: Double]?
    let grossPay: Double?
    let totalDeductions: Double?
    let netRemittance: Double?
    let month: String?
    let year: Int?
}

