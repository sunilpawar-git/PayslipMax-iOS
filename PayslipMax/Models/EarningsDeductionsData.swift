import Foundation

/// Data structure to hold parsed earnings and deductions data
/// This model represents the structured financial data extracted from payslip parsing
struct EarningsDeductionsData {
    // Standard earnings
    var bpay: Double = 0
    var da: Double = 0
    var msp: Double = 0

    // Standard deductions
    var dsop: Double = 0
    var agif: Double = 0
    var itax: Double = 0

    // Non-standard components
    var knownEarnings: [String: Double] = [:]
    var knownDeductions: [String: Double] = [:]

    // Miscellaneous components
    var miscCredits: Double = 0
    var miscDebits: Double = 0

    // Totals
    var grossPay: Double = 0
    var totalDeductions: Double = 0

    // Raw data for reference
    var rawEarnings: [String: Double] = [:]
    var rawDeductions: [String: Double] = [:]

    // Tracking for unknown abbreviations
    var unknownEarnings: [String: Double] = [:]
    var unknownDeductions: [String: Double] = [:]
}

// MARK: - Computed Properties
extension EarningsDeductionsData {
    /// Calculates the net pay from gross pay and total deductions
    var netPay: Double {
        return grossPay - totalDeductions
    }

    /// Returns all earnings (standard + known + unknown)
    var allEarnings: [String: Double] {
        var all = knownEarnings
        if bpay > 0 { all["BPAY"] = bpay }
        if da > 0 { all["DA"] = da }
        if msp > 0 { all["MSP"] = msp }
        all.merge(unknownEarnings) { (current, _) in current }
        return all
    }

    /// Returns all deductions (standard + known + unknown)
    var allDeductions: [String: Double] {
        var all = knownDeductions
        if dsop > 0 { all["DSOP"] = dsop }
        if agif > 0 { all["AGIF"] = agif }
        if itax > 0 { all["ITAX"] = itax }
        all.merge(unknownDeductions) { (current, _) in current }
        return all
    }
}

// MARK: - Validation
extension EarningsDeductionsData {
    /// Validates that the data structure is consistent
    func isValid() -> Bool {
        return grossPay >= 0 && totalDeductions >= 0 && netPay >= 0
    }

    /// Resets all values to zero
    mutating func reset() {
        bpay = 0
        da = 0
        msp = 0
        dsop = 0
        agif = 0
        itax = 0
        knownEarnings.removeAll()
        knownDeductions.removeAll()
        miscCredits = 0
        miscDebits = 0
        grossPay = 0
        totalDeductions = 0
        rawEarnings.removeAll()
        rawDeductions.removeAll()
        unknownEarnings.removeAll()
        unknownDeductions.removeAll()
    }
}
