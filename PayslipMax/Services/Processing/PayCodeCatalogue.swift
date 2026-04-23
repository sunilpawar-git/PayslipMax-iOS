import Foundation

/// Single Source of Truth for known military pay code classifications.
/// Both the section splitter (JCOORTextSectionSplitter) and the cross-line
/// regex engine (UniversalPayCodeSearchEngine+Helpers) reference these sets.
enum PayCodeCatalogue {

    // MARK: - Credit (Earnings) Codes

    /// Pay codes that appear on the Credits / Earnings side of a JCO/OR payslip
    static let creditCodes: Set<String> = [
        "BPAY", "DA", "MSP", "TPAL", "HRA", "HRALF", "LRA", "PMHA",
        "CLPAY", "CL PAY", "GSPAY", "RISK", "RUMCIG", "RH11", "RH12",
        "BAND PAY", "BASIC PAY", "DEARNESS ALLOWANCE"
    ]

    // MARK: - Debit (Deduction) Codes

    /// Pay codes that appear on the Debits / Deductions side of a JCO/OR payslip
    static let debitCodes: Set<String> = [
        "DSOP", "AGIF", "PLI", "ITAX", "INCOME TAX", "CGEIS", "CGHS",
        "ECHS", "AFPF", "GPF", "NPS", "LOAN", "LOANS", "E-TICKETING"
    ]

    // MARK: - Helpers

    /// Returns `true` if the uppercased line contains at least one credit code token
    static func isCredit(_ uppercasedLine: String) -> Bool {
        creditCodes.contains(where: { uppercasedLine.contains($0) })
    }

    /// Returns `true` if the uppercased line contains at least one debit code token
    static func isDebit(_ uppercasedLine: String) -> Bool {
        debitCodes.contains(where: { uppercasedLine.contains($0) })
    }
}
