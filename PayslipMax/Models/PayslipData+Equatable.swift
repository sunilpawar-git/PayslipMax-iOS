import Foundation

// MARK: - PayslipData: Equatable

/// Equatable conformance for PayslipData.
/// Equality is determined by the financial identity of a payslip:
/// name, credits, debits, deductions, and earnings dictionaries.
extension PayslipData: Equatable {
    public static func == (lhs: PayslipData, rhs: PayslipData) -> Bool {
        lhs.name == rhs.name &&
        lhs.totalCredits == rhs.totalCredits &&
        lhs.totalDebits == rhs.totalDebits &&
        lhs.dsop == rhs.dsop &&
        lhs.incomeTax == rhs.incomeTax &&
        lhs.netRemittance == rhs.netRemittance &&
        lhs.allEarnings == rhs.allEarnings &&
        lhs.allDeductions == rhs.allDeductions
    }
}
