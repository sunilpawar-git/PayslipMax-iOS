//
//  MilitaryPayslipValidator.swift
//  PayslipMax
//
//  Extracted from UnifiedMilitaryPayslipProcessor for architectural compliance
//  Handles validation of payslip data consistency
//

import Foundation

/// Protocol for military payslip validation following SOLID principles
protocol MilitaryPayslipValidatorProtocol {
    func validateTotals(earnings: [String: Double], deductions: [String: Double], statedCredits: Double, statedDebits: Double) -> (creditsVariance: Double, debitsVariance: Double)
}

/// Service responsible for validating military payslip data consistency
/// Implements single responsibility principle for data validation
class MilitaryPayslipValidator: MilitaryPayslipValidatorProtocol {

    /// Validates extracted totals against stated totals from payslip
    func validateTotals(earnings: [String: Double], deductions: [String: Double], statedCredits: Double, statedDebits: Double) -> (creditsVariance: Double, debitsVariance: Double) {

        // Calculate extracted totals
        let extractedCredits = earnings.values.reduce(0, +)
        let extractedDebits = deductions.values.reduce(0, +)

        // Calculate variances
        let creditsVariance = statedCredits > 0 ? abs(extractedCredits - statedCredits) / statedCredits * 100 : 0
        let debitsVariance = statedDebits > 0 ? abs(extractedDebits - statedDebits) / statedDebits * 100 : 0

        // Log validation results
        print("[MilitaryPayslipValidator] Credits validation - Extracted: ₹\(extractedCredits), Stated: ₹\(statedCredits), Variance: \(String(format: "%.1f", creditsVariance))%")
        print("[MilitaryPayslipValidator] Debits validation - Extracted: ₹\(extractedDebits), Stated: ₹\(statedDebits), Variance: \(String(format: "%.1f", debitsVariance))%")

        // Alert if variance is significant (>5%)
        if creditsVariance > 5.0 {
            print("[MilitaryPayslipValidator] ⚠️ High credits variance: \(String(format: "%.1f", creditsVariance))%")
        }

        if debitsVariance > 5.0 {
            print("[MilitaryPayslipValidator] ⚠️ High debits variance: \(String(format: "%.1f", debitsVariance))%")
        }

        return (creditsVariance, debitsVariance)
    }

    /// Validates individual component values for reasonableness
    func validateComponentValues(earnings: [String: Double], deductions: [String: Double]) -> [String] {
        var warnings: [String] = []

        // Validate basic pay is reasonable
        if let basicPay = earnings["Basic Pay"], basicPay < 10000 || basicPay > 500000 {
            warnings.append("Basic Pay amount seems unusual: ₹\(basicPay)")
        }

        // Validate DA is reasonable percentage of basic pay
        if let basicPay = earnings["Basic Pay"], let da = earnings["Dearness Allowance"] {
            let daPercentage = (da / basicPay) * 100
            if daPercentage < 20 || daPercentage > 100 {
                warnings.append("DA percentage seems unusual: \(String(format: "%.1f", daPercentage))% of Basic Pay")
            }
        }

        // Validate DSOP is reasonable
        if let dsop = deductions["DSOP"], dsop < 5000 || dsop > 100000 {
            warnings.append("DSOP amount seems unusual: ₹\(dsop)")
        }

        // Validate negative values don't exist
        for (key, value) in earnings {
            if value < 0 {
                warnings.append("Negative earnings value found: \(key) = ₹\(value)")
            }
        }

        for (key, value) in deductions {
            if value < 0 {
                warnings.append("Negative deductions value found: \(key) = ₹\(value)")
            }
        }

        return warnings
    }

    /// Validates that essential military payslip components are present
    func validateEssentialComponents(earnings: [String: Double], deductions: [String: Double]) -> [String] {
        var missingComponents: [String] = []

        // Essential earnings components
        if earnings["Basic Pay"] == nil {
            missingComponents.append("Basic Pay")
        }

        if earnings["Military Service Pay"] == nil {
            missingComponents.append("Military Service Pay (MSP)")
        }

        // Essential deduction components
        if deductions["DSOP"] == nil {
            missingComponents.append("DSOP (Defence Service Officers Provident Fund)")
        }

        if deductions["AGIF"] == nil {
            missingComponents.append("AGIF (Army Group Insurance Fund)")
        }

        if !missingComponents.isEmpty {
            print("[MilitaryPayslipValidator] ⚠️ Missing essential components: \(missingComponents.joined(separator: ", "))")
        }

        return missingComponents
    }
}
