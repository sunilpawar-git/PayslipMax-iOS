import Foundation
import FoundationModels

/// Individual pay component extracted by the on-device model
@available(iOS 26, *)
@Generable(description: "A single pay component with its code and amount")
struct PayComponentSchema {
    @Guide(description: "Standard pay code abbreviation like BPAY, DA, MSP, DSOP, ITAX")
    var code: String

    @Guide(description: "Amount in Indian Rupees", .minimum(0))
    var amount: Double
}

/// Schema for on-device LLM guided generation of payslip data.
/// Uses @Generable for constrained sampling -- the model can only produce
/// structurally valid output matching this schema.
@available(iOS 26, *)
@Generable(description: "Extracted Indian military payslip financial data")
struct PayslipExtractionSchema {

    @Guide(description: "Earnings/credits: pay components like BPAY, DA, MSP, TPAL, HRA",
           .minimumCount(1), .maximumCount(30))
    var earnings: [PayComponentSchema]

    @Guide(description: "Deductions/debits: components like DSOP, AGIF, ITAX, PLI",
           .maximumCount(30))
    var deductions: [PayComponentSchema]

    @Guide(description: "Total of all earnings / credits", .minimum(0))
    var grossPay: Double

    @Guide(description: "Total of all deductions / debits", .minimum(0))
    var totalDeductions: Double

    @Guide(description: "Net amount after deductions", .minimum(0))
    var netRemittance: Double

    @Guide(description: "Month name like JANUARY, FEBRUARY")
    var month: String?

    @Guide(description: "Four-digit year like 2025")
    var year: Int?
}

/// Converts the @Generable schema output to the protocol-neutral result type
@available(iOS 26, *)
extension PayslipExtractionSchema {
    func toResult() -> OnDeviceLLMResult {
        // Sum duplicate codes rather than silently dropping them
        let earningsDict = Dictionary(
            earnings.map { ($0.code, $0.amount) },
            uniquingKeysWith: { $0 + $1 }
        )
        let deductionsDict = Dictionary(
            deductions.map { ($0.code, $0.amount) },
            uniquingKeysWith: { $0 + $1 }
        )
        return OnDeviceLLMResult(
            earnings: earningsDict,
            deductions: deductionsDict,
            grossPay: grossPay,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance,
            month: month,
            year: year
        )
    }
}
