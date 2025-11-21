import Foundation

/// Represents anchor values extracted from the payslip header (totals)
struct PayslipAnchors {
    let grossPay: Double
    let totalDeductions: Double
    let netRemittance: Double

    /// Validates that the anchor equation holds: Gross - Deductions = Net
    var isEquationValid: Bool {
        let calculatedNet = grossPay - totalDeductions
        let difference = abs(calculatedNet - netRemittance)
        // Allow ₹1 rounding difference
        return difference <= 1.0
    }

    /// The calculated net based on gross and deductions
    var calculatedNet: Double {
        return grossPay - totalDeductions
    }

    /// Difference between calculated and stated net remittance
    var netDifference: Double {
        return abs(calculatedNet - netRemittance)
    }
}

/// Result of a component validation operation
struct ComponentValidationResult {
    let isValid: Bool
    var missingComponents: [String] = []
    var warnings: [String] = []
    var error: String? = nil

    static var success: ComponentValidationResult {
        return ComponentValidationResult(isValid: true)
    }

    static func failure(error: String) -> ComponentValidationResult {
        return ComponentValidationResult(isValid: false, error: error)
    }

    static func failure(missingComponents: [String]) -> ComponentValidationResult {
        return ComponentValidationResult(
            isValid: false,
            missingComponents: missingComponents,
            error: "Missing mandatory components: \(missingComponents.joined(separator: ", "))"
        )
    }
}

/// Errors that can occur during payslip processing
enum PayslipProcessingError: Error, LocalizedError {
    case invalidAnchors(PayslipAnchors)
    case missingMandatoryComponents([String])
    case totalsMismatch(earnings: Double, expected: Double, deductions: Double, expectedDeductions: Double)
    case noText
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .invalidAnchors(let anchors):
            return "Invalid payslip anchors: Gross(₹\(anchors.grossPay)) - Deductions(₹\(anchors.totalDeductions)) ≠ Net(₹\(anchors.netRemittance)). Difference: ₹\(anchors.netDifference)"
        case .missingMandatoryComponents(let components):
            return "Missing mandatory components: \(components.joined(separator: ", "))"
        case .totalsMismatch(let earnings, let expected, let deductions, let expectedDeductions):
            return "Totals mismatch - Earnings: ₹\(earnings) vs ₹\(expected), Deductions: ₹\(deductions) vs ₹\(expectedDeductions)"
        case .noText:
            return "No text extracted from PDF"
        case .parsingFailed:
            return "Failed to parse payslip"
        }
    }
}
