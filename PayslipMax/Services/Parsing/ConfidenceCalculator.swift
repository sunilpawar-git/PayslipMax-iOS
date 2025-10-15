import Foundation

/// Calculates confidence score for simplified payslip parsing
/// Uses 5 validation checks to determine data quality (0.0 to 1.0)
class ConfidenceCalculator {

    // MARK: - Confidence Calculation

    /// Calculates overall confidence score based on totals accuracy
    /// Balanced logic: Requires both totals consistency AND core field presence
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

        // Check 1: Gross Pay Extracted (20 points)
        if grossPay > 0 {
            score += 0.20
        }

        // Check 2: Total Deductions Extracted (20 points)
        if totalDeductions > 0 {
            score += 0.20
        }

        // Check 3: Net Remittance Consistency (50 points) - MOST IMPORTANT
        // Verifies the math: Gross - Deductions = Net
        if grossPay > 0 && totalDeductions > 0 && netRemittance > 0 {
            let calculatedNet = grossPay - totalDeductions
            let difference = abs(netRemittance - calculatedNet)
            let percentDifference = difference / max(netRemittance, calculatedNet)

            if percentDifference <= 0.01 {
                // Perfect match (±1%)
                score += 0.50
            } else if percentDifference <= 0.05 {
                // Good match (±5%)
                score += 0.40
            } else if percentDifference <= 0.10 {
                // Acceptable match (±10%)
                score += 0.20
            }
            // else: no points (>10% difference)
        }

        // Check 4: Core Fields Present (10 points)
        // Ensures we're extracting meaningful data, not just random numbers
        let coreFields = [basicPay, dearnessAllowance, militaryServicePay, dsop, agif]
        let presentCount = coreFields.filter { $0 > 0 }.count

        if presentCount >= 3 {
            score += 0.10
        } else if presentCount >= 1 {
            score += 0.05
        }
        // 0 fields: no points

        return min(1.0, score)
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

