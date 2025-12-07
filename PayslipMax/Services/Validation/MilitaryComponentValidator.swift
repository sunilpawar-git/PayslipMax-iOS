//
//  MilitaryComponentValidator.swift
//  PayslipMax
//
//  Created for military component validation logic
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Service responsible for validating military payslip components
/// Implements SOLID principles with single responsibility for validation
class MilitaryComponentValidator {

    private let payStructure: MilitaryPayStructure?

    init(payStructure: MilitaryPayStructure?) {
        self.payStructure = payStructure
    }

    // Note: Using forward declarations for types defined in DynamicMilitaryPatternService
    // This follows the single source of truth principle

    /// Pre-validates extracted amount before adding to results (SOLID: Single Responsibility)
    func preValidateExtraction(_ component: String, amount: Double, basicPay: Double?, level: String?) -> Bool {
        // swiftlint:disable no_hardcoded_strings
        // Prevent false positives by pre-validating suspicious amounts
        switch component.uppercased() {
        case "HRA":
            guard let basicPay = basicPay else {
                return false
            }
            // Reject HRA if it's more than 3x basic pay (obvious false positive)
            return amount <= basicPay * 3.0
        case "DA":
            guard let basicPay = basicPay else {
                return false
            }
            // Reject DA if it's more than 100% of basic pay
            return amount <= basicPay * 1.0
        default:
            return true // Allow other components through
        }
        // swiftlint:enable no_hardcoded_strings
    }

    // swiftlint:disable function_body_length cyclomatic_complexity
    /// Validates allowance amounts against military standards
    func validateAllowance(_ component: String, amount: Double, basicPay: Double?, level: String?) -> ValidationStatus {
        // swiftlint:disable no_hardcoded_strings
        switch component.uppercased() {
        case "MSP":
            let expectedMSP = 15_500.0 // Standard MSP amount
            return amount == expectedMSP ?
                .valid("MSP matches expected ₹\(expectedMSP)") :
                .warning("MSP ₹\(amount) differs from expected ₹\(expectedMSP)")

        case "DA":
            guard let basicPay = basicPay else {
                return .unknown("Basic Pay required for DA validation")
            }
            // DA varies based on pay level and policy - allow flexible range (40-65% of basic pay)
            let minDA = basicPay * 0.40
            let maxDA = basicPay * 0.65
            let standardDA = basicPay * 0.50

            if amount >= minDA && amount <= maxDA {
                return .valid("DA ₹\(amount) within valid range (40-65% of basic pay)")
            } else if abs(amount - standardDA) / standardDA <= 0.25 {
                return .warning("DA ₹\(amount) outside standard range but within acceptable variance")
            } else {
                return .invalid("DA ₹\(amount) significantly outside expected range ₹\(minDA)-₹\(maxDA)")
            }

        case "HRA":
            guard let basicPay = basicPay else {
                return .unknown("Basic Pay required for HRA validation")
            }
            // Check against different city classifications
            let xClassHRA = basicPay * 0.24
            let yClassHRA = basicPay * 0.16
            let zClassHRA = basicPay * 0.08

            if abs(amount - xClassHRA) / xClassHRA <= 0.1 {
                return .valid("HRA matches X-class city rate")
            } else if abs(amount - yClassHRA) / yClassHRA <= 0.1 {
                return .valid("HRA matches Y-class city rate")
            } else if abs(amount - zClassHRA) / zClassHRA <= 0.1 {
                return .valid("HRA matches Z-class city rate")
            } else {
                return .warning("HRA ₹\(amount) doesn't match standard city classifications")
            }

        case "TPTA":
            let expectedTPTA = 3_600.0
            return amount == expectedTPTA ?
                .valid("TPTA matches expected ₹\(expectedTPTA)") :
                .warning("TPTA ₹\(amount) differs from expected ₹\(expectedTPTA)")

        case "TPTADA":
            // TPTADA is typically a small percentage of TPTA (around 55% of TPTA)
            let expectedTPTADA = 1_980.0 // Standard TPTADA amount
            return amount == expectedTPTADA ?
                .valid("TPTADA matches expected ₹\(expectedTPTADA)") :
                .warning("TPTADA ₹\(amount) differs from expected ₹\(expectedTPTADA)")

        case let code where code.hasPrefix("RH"):
            // Universal validation for all RH codes: RH11, RH12, RH13, RH21, RH22, RH23, RH31, RH32, RH33
            guard let payStructure = payStructure, let level = level,
                  let levelData = payStructure.payLevels[level] else {
                // Fallback validation based on typical RH amounts for different levels
                // RH11: ₹15K-₹50K, RH33: ₹3K-₹15K (range varies by RH code)
                let (minRange, maxRange) = getRHValidationRange(for: code)
                let isReasonable = amount >= minRange && amount <= maxRange
                return isReasonable ?
                    .valid("\(code) ₹\(amount) within reasonable range") :
                    .warning("\(code) ₹\(amount) outside typical range ₹\(Int(minRange))-₹\(Int(maxRange))")
            }

            // Level-specific RH validation based on rank and RH code
            let (minMultiplier, maxMultiplier) = getRHMultipliers(for: code)
            let minRH = levelData.basicPayRange.min * minMultiplier
            let maxRH = levelData.basicPayRange.max * maxMultiplier

            if amount >= minRH && amount <= maxRH {
                return .valid("\(code) ₹\(amount) appropriate for \(levelData.rank)")
            } else {
                return .warning(
                    "\(code) ₹\(amount) outside expected range ₹\(Int(minRH))-₹\(Int(maxRH)) for \(levelData.rank)"
                )
            }

        default:
            return .unknown("Validation not implemented for \(component)")
        }
        // swiftlint:enable no_hardcoded_strings
    }
    // swiftlint:enable function_body_length cyclomatic_complexity

    /// Validates extracted BPAY against known military pay ranges
    func validateBasicPay(_ amount: Double, forLevel level: String? = nil) -> ValidationStatus {
        // swiftlint:disable no_hardcoded_strings
        guard let payStructure = payStructure else {
            return .unknown("Pay structure not loaded")
        }

        // If level is specified, validate against that level
        if let level = level, let levelData = payStructure.payLevels[level] {
            return validateAmountInRange(
                amount,
                range: levelData.basicPayRange,
                component: "Basic Pay for \(levelData.rank)"
            )
        }

        // Otherwise, check if amount falls within any valid range
        for (_, levelData) in payStructure.payLevels {
            if amount >= levelData.basicPayRange.min && amount <= levelData.basicPayRange.max {
                return .valid("Amount valid for \(levelData.rank) (\(levelData.level))")
            }
        }

        return .invalid("Basic Pay ₹\(amount) doesn't match any known military pay level")
        // swiftlint:enable no_hardcoded_strings
    }

    // MARK: - Private Methods

    private func validateAmountInRange(_ amount: Double, range: PayRange, component: String) -> ValidationStatus {
        // swiftlint:disable no_hardcoded_strings
        if amount >= range.min && amount <= range.max {
            return .valid("\(component) within valid range")
        } else if amount < range.min {
            return .warning("\(component) ₹\(amount) below minimum ₹\(range.min)")
        } else {
            return .warning("\(component) ₹\(amount) above maximum ₹\(range.max)")
        }
        // swiftlint:enable no_hardcoded_strings
    }

    // MARK: - Private RH Validation Helpers

    /// Returns validation range for specific RH codes without pay structure context
    /// Based on Phase 2.3 requirements and real-world RH allowance data
    private func getRHValidationRange(for code: String) -> (min: Double, max: Double) {
        // swiftlint:disable no_hardcoded_strings
        switch code.uppercased() {
        case "RH11":
            return (15_000, 50_000) // Higher range for RH11
        case "RH12":
            return (5_000, 50_000)  // Standard RH12 range (as per existing logic)
        case "RH13":
            return (10_000, 45_000) // RH13 range
        case "RH21":
            return (8_000, 40_000)  // RH21 range
        case "RH22":
            return (6_000, 35_000)  // RH22 range
        case "RH23":
            return (4_000, 30_000)  // RH23 range
        case "RH31":
            return (5_000, 25_000)  // RH31 range
        case "RH32":
            return (4_000, 20_000)  // RH32 range
        case "RH33":
            return (3_000, 15_000)  // Lower range for RH33
        default:
            return (3_000, 50_000)  // Default RH range for unknown codes
        }
        // swiftlint:enable no_hardcoded_strings
    }

    /// Returns multipliers for level-specific RH validation based on basic pay
    /// Different RH codes have different multiplier ranges relative to basic pay
    private func getRHMultipliers(for code: String) -> (min: Double, max: Double) {
        // swiftlint:disable no_hardcoded_strings
        switch code.uppercased() {
        case "RH11":
            return (0.08, 0.20)  // 8-20% of basic pay for RH11
        case "RH12":
            return (0.05, 0.15)  // 5-15% of basic pay for RH12 (existing logic)
        case "RH13":
            return (0.06, 0.18)  // 6-18% of basic pay for RH13
        case "RH21":
            return (0.04, 0.16)  // 4-16% of basic pay for RH21
        case "RH22":
            return (0.03, 0.14)  // 3-14% of basic pay for RH22
        case "RH23":
            return (0.02, 0.12)  // 2-12% of basic pay for RH23
        case "RH31":
            return (0.03, 0.10)  // 3-10% of basic pay for RH31
        case "RH32":
            return (0.02, 0.08)  // 2-8% of basic pay for RH32
        case "RH33":
            return (0.01, 0.06)  // 1-6% of basic pay for RH33 (lowest)
        default:
            return (0.01, 0.20)  // Default range for unknown RH codes
        }
        // swiftlint:enable no_hardcoded_strings
    }

    /// FALLBACK VALIDATION FIX: Grade-agnostic validation for critical components
    /// Prevents rejection of valid DA amounts when grade detection fails
    func applyFallbackValidation(_ component: String, amount: Double, basicPay: Double?) -> Bool {
        // swiftlint:disable no_hardcoded_strings
        guard let basicPay = basicPay else {
            return false
        }

        switch component {
        case "DA":
            // DA typically ranges from 40-65% of BasicPay for officers
            let daPercentage = (amount / basicPay) * 100
            let isValidDARange = daPercentage >= 35 && daPercentage <= 70  // Slightly expanded range
            let percentageText = String(format: "%.1f", daPercentage)
            let message = "[MilitaryComponentValidator] Fallback DA validation: ₹\(amount) = "
                + "\(percentageText)% of BasicPay"
            print(message)
            return isValidDARange

        case "RH12":
            // RH12 typically ranges from ₹15,000 to ₹25,000 for officers
            return amount >= 15_000 && amount <= 30_000

        case "MSP":
            // MSP is typically ₹15,500 for officers
            return amount >= 15_000 && amount <= 16_000

        case "TPTA", "TPTADA":
            // Transport allowances typically range from ₹1,000 to ₹5,000
            return amount >= 1_000 && amount <= 10_000

        default:
            // For other components, be more lenient when grade is unknown
            return amount > 0 && amount < 1_000_000  // Basic sanity check
        }
        // swiftlint:enable no_hardcoded_strings
    }
}
