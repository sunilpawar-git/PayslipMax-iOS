import Foundation

/// Calculates confidence score for simplified payslip parsing
/// Uses 5 validation checks to determine data quality (0.0 to 1.0)
class ConfidenceCalculator {
    
    // MARK: - Confidence Calculation
    
    /// Calculates overall confidence score based on validation checks
    /// - Returns: Confidence score from 0.0 (poor) to 1.0 (excellent)
    func calculate(
        basicPay: Double,
        dearnessAllowance: Double,
        militaryServicePay: Double,
        grossPay: Double,
        dsop: Double,
        agif: Double,
        incomeTax: Double,
        totalDeductions: Double,
        netRemittance: Double
    ) async -> Double {
        var score = 0.0
        
        // Check 1: Gross Pay Validation (20 points)
        // Gross = BPAY + DA + MSP + Other (±2% tolerance)
        let calculatedGross = basicPay + dearnessAllowance + militaryServicePay
        if validateTotals(calculated: calculatedGross, actual: grossPay, tolerance: 0.02, allowLess: true) {
            score += 0.20
        }
        
        // Check 2: Total Deductions Validation (20 points)
        // Total Deductions = DSOP + AGIF + Tax + Other (±2% tolerance)
        let calculatedDeductions = dsop + agif + incomeTax
        if validateTotals(calculated: calculatedDeductions, actual: totalDeductions, tolerance: 0.02, allowLess: true) {
            score += 0.20
        }
        
        // Check 3: Net Remittance Validation (30 points)
        // Net = Gross - Total Deductions (±1% tolerance)
        let calculatedNet = grossPay - totalDeductions
        if validateTotals(calculated: calculatedNet, actual: netRemittance, tolerance: 0.01, allowLess: false) {
            score += 0.30
        }
        
        // Check 4: Core Fields Non-Zero (25 points total)
        var nonZeroScore = 0.0
        
        // Essential earnings (15 points)
        if basicPay > 0 { nonZeroScore += 0.05 }
        if dearnessAllowance > 0 { nonZeroScore += 0.05 }
        if militaryServicePay > 0 { nonZeroScore += 0.05 }
        
        // Essential deductions (10 points)
        if dsop > 0 { nonZeroScore += 0.05 }
        if agif > 0 { nonZeroScore += 0.05 }
        
        score += nonZeroScore
        
        // Check 5: Reasonable Value Ranges (5 points)
        if validateRanges(
            basicPay: basicPay,
            dearnessAllowance: dearnessAllowance,
            militaryServicePay: militaryServicePay,
            dsop: dsop,
            agif: agif
        ) {
            score += 0.05
        }
        
        return min(1.0, score)
    }
    
    // MARK: - Validation Helpers
    
    /// Validates that calculated and actual values match within tolerance
    private func validateTotals(
        calculated: Double,
        actual: Double,
        tolerance: Double,
        allowLess: Bool
    ) -> Bool {
        guard actual > 0 else { return false }
        
        let difference = abs(actual - calculated)
        let percentDifference = difference / actual
        
        // Exact match or within tolerance
        if percentDifference <= tolerance {
            return true
        }
        
        // If allowLess is true, calculated can be less than actual (for partial sums)
        // This handles cases where we have "other earnings/deductions" not yet parsed
        // The calculated value should be at least 90% of actual to get credit
        // This prevents giving points when the values are wildly different
        if allowLess && calculated < actual && calculated > 0 {
            let ratio = calculated / actual
            // Calculated should be at least 90% of actual value
            return ratio >= 0.90
        }
        
        return false
    }
    
    /// Validates that all values are within reasonable ranges for military payslips
    private func validateRanges(
        basicPay: Double,
        dearnessAllowance: Double,
        militaryServicePay: Double,
        dsop: Double,
        agif: Double
    ) -> Bool {
        // Basic Pay range: ₹50,000 to ₹300,000
        let bpayValid = basicPay >= 50000 && basicPay <= 300000
        
        // Dearness Allowance range: ₹30,000 to ₹200,000 (roughly 40-65% of basic pay)
        let daValid = dearnessAllowance >= 30000 && dearnessAllowance <= 200000
        
        // MSP range: ₹10,000 to ₹25,000 (usually ₹15,500)
        let mspValid = militaryServicePay >= 10000 && militaryServicePay <= 25000
        
        // DSOP range: ₹10,000 to ₹100,000
        let dsopValid = dsop >= 10000 && dsop <= 100000
        
        // AGIF range: ₹5,000 to ₹30,000
        let agifValid = agif >= 5000 && agif <= 30000
        
        // At least 4 out of 5 should be valid
        let validCount = [bpayValid, daValid, mspValid, dsopValid, agifValid].filter { $0 }.count
        return validCount >= 4
    }
}

// MARK: - Confidence Level Helpers

extension ConfidenceCalculator {
    
    /// Returns a descriptive level for a confidence score
    static func confidenceLevel(for score: Double) -> ConfidenceLevel {
        switch score {
        case 0.9...1.0:
            return .excellent
        case 0.75..<0.9:
            return .good
        case 0.5..<0.75:
            return .reviewRecommended
        default:
            return .manualVerificationRequired
        }
    }
    
    /// Returns a color for a confidence score
    static func confidenceColor(for score: Double) -> String {
        switch confidenceLevel(for: score) {
        case .excellent:
            return "green"
        case .good:
            return "yellow"
        case .reviewRecommended:
            return "orange"
        case .manualVerificationRequired:
            return "red"
        }
    }
}

/// Confidence level enumeration
enum ConfidenceLevel: String {
    case excellent = "Excellent"
    case good = "Good"
    case reviewRecommended = "Review Recommended"
    case manualVerificationRequired = "Manual Verification Required"
    
    var description: String {
        return self.rawValue
    }
}

