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
        // Prevent false positives by pre-validating suspicious amounts
        switch component.uppercased() {
        case "HRA":
            guard let basicPay = basicPay else { return false }
            // Reject HRA if it's more than 3x basic pay (obvious false positive)
            return amount <= basicPay * 3.0
        case "DA":
            guard let basicPay = basicPay else { return false }
            // Reject DA if it's more than 100% of basic pay
            return amount <= basicPay * 1.0
        default:
            return true // Allow other components through
        }
    }
    
    /// Validates allowance amounts against military standards
    func validateAllowance(_ component: String, amount: Double, basicPay: Double?, level: String?) -> ValidationStatus {
        switch component.uppercased() {
        case "MSP":
            let expectedMSP = 15500.0 // Standard MSP amount
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
            let expectedTPTA = 3600.0
            return amount == expectedTPTA ? 
                .valid("TPTA matches expected ₹\(expectedTPTA)") : 
                .warning("TPTA ₹\(amount) differs from expected ₹\(expectedTPTA)")
            
        case "TPTADA":
            // TPTADA is typically a small percentage of TPTA (around 55% of TPTA)
            let expectedTPTADA = 1980.0 // Standard TPTADA amount
            return amount == expectedTPTADA ? 
                .valid("TPTADA matches expected ₹\(expectedTPTADA)") : 
                .warning("TPTADA ₹\(amount) differs from expected ₹\(expectedTPTADA)")
            
        case "RH12":
            guard let payStructure = payStructure, let level = level,
                  let levelData = payStructure.payLevels[level] else {
                // Fallback validation based on typical RH12 amounts for different levels
                let isReasonable = amount >= 5000 && amount <= 50000
                return isReasonable ? 
                    .valid("RH12 ₹\(amount) within reasonable range") : 
                    .warning("RH12 ₹\(amount) outside typical range ₹5,000-₹50,000")
            }
            
            // Level-specific RH12 validation based on rank
            let minRH12 = levelData.basicPayRange.min * 0.05 // 5% of min basic pay
            let maxRH12 = levelData.basicPayRange.max * 0.15 // 15% of max basic pay
            
            if amount >= minRH12 && amount <= maxRH12 {
                return .valid("RH12 ₹\(amount) appropriate for \(levelData.rank)")
            } else {
                return .warning("RH12 ₹\(amount) outside expected range ₹\(minRH12)-₹\(maxRH12) for \(levelData.rank)")
            }
            
        default:
            return .unknown("Validation not implemented for \(component)")
        }
    }
    
    /// Validates extracted BPAY against known military pay ranges
    func validateBasicPay(_ amount: Double, forLevel level: String? = nil) -> ValidationStatus {
        guard let payStructure = payStructure else {
            return .unknown("Pay structure not loaded")
        }
        
        // If level is specified, validate against that level
        if let level = level, let levelData = payStructure.payLevels[level] {
            return validateAmountInRange(amount, range: levelData.basicPayRange, component: "Basic Pay for \(levelData.rank)")
        }
        
        // Otherwise, check if amount falls within any valid range
        for (_, levelData) in payStructure.payLevels {
            if amount >= levelData.basicPayRange.min && amount <= levelData.basicPayRange.max {
                return .valid("Amount valid for \(levelData.rank) (\(levelData.level))")
            }
        }
        
        return .invalid("Basic Pay ₹\(amount) doesn't match any known military pay level")
    }
    
    // MARK: - Private Methods
    
    private func validateAmountInRange(_ amount: Double, range: PayRange, component: String) -> ValidationStatus {
        if amount >= range.min && amount <= range.max {
            return .valid("\(component) within valid range")
        } else if amount < range.min {
            return .warning("\(component) ₹\(amount) below minimum ₹\(range.min)")
        } else {
            return .warning("\(component) ₹\(amount) above maximum ₹\(range.max)")
        }
    }
}
