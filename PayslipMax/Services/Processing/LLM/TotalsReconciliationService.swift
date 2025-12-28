//
//  TotalsReconciliationService.swift
//  PayslipMax
//
//  Handles reconciliation of payslip totals to ensure accuracy
//  Ensures: grossPay - totalDeductions = netRemittance
//

import Foundation
import OSLog

/// Result of LLM totals reconciliation check
struct LLMReconciliationResult {
    let isReconciled: Bool
    let grossPay: Double
    let totalDeductions: Double
    let netRemittance: Double
    let earningsSum: Double
    let deductionsSum: Double
    let fundamentalEquationError: Double  // grossPay - totalDeductions - netRemittance
    let earningsSumError: Double  // Percentage difference
    let deductionsSumError: Double  // Percentage difference

    /// Whether a retry with focused prompt is recommended
    var needsRetry: Bool {
        return !isReconciled && (earningsSumError > 0.10 || deductionsSumError > 0.10)
    }
}

/// Service for reconciling payslip totals
enum TotalsReconciliationService {

    // MARK: - Reconciliation

    /// Reconciles totals ensuring fundamental equation holds: grossPay - totalDeductions = netRemittance
    /// - Parameters:
    ///   - response: LLM response to reconcile
    ///   - logger: Logger for recording operations
    /// - Returns: Reconciled response with corrected totals
    static func reconcileTotals(
        _ response: LLMPayslipResponse,
        logger: os.Logger? = nil
    ) -> LLMPayslipResponse {
        let gross = response.grossPay ?? 0
        let net = response.netRemittance ?? 0

        // Rule 1: totalDeductions MUST equal gross - net (fundamental equation)
        let calculatedDeductions = gross - net

        // Rule 2: If LLM's totalDeductions differs significantly from calculated, use calculated
        var finalTotalDeductions = response.totalDeductions ?? calculatedDeductions
        let deductionsDifference = abs(finalTotalDeductions - calculatedDeductions)

        if deductionsDifference > 100 && gross > 0 && net > 0 {
            logger?.info("🔧 Reconciling totalDeductions: \(finalTotalDeductions) → \(calculatedDeductions)")
            finalTotalDeductions = calculatedDeductions
        }

        // Rule 3: If totalDeductions equals grossPay, it's wrong (TOTAL DEBITS = TOTAL CREDITS issue)
        if abs(finalTotalDeductions - gross) < 1.0 && net > 0 {
            logger?.warning("⚠️ totalDeductions equals grossPay - using calculated value")
            finalTotalDeductions = calculatedDeductions
        }

        // Rule 4: totalDeductions must be less than grossPay
        if finalTotalDeductions >= gross && gross > 0 && net > 0 {
            logger?.warning("⚠️ totalDeductions >= grossPay - recalculating from net")
            finalTotalDeductions = calculatedDeductions
        }

        // Rule 5: Ensure netRemittance is positive and reasonable
        var finalNetRemittance = net
        if finalNetRemittance <= 0 && gross > 0 && finalTotalDeductions > 0 {
            finalNetRemittance = gross - finalTotalDeductions
            logger?.info("🔧 Calculating missing netRemittance: \(finalNetRemittance)")
        }

        return LLMPayslipResponse(
            earnings: response.earnings,
            deductions: response.deductions,
            grossPay: gross,
            totalDeductions: finalTotalDeductions,
            netRemittance: finalNetRemittance,
            month: response.month,
            year: response.year
        )
    }

    /// Checks if totals are properly reconciled
    /// - Parameter response: Response to check
    /// - Returns: LLMReconciliationResult with detailed error information
    static func checkReconciliation(_ response: LLMPayslipResponse) -> LLMReconciliationResult {
        let gross = response.grossPay ?? 0
        let deductions = response.totalDeductions ?? 0
        let net = response.netRemittance ?? 0
        let earningsSum = response.earnings?.values.reduce(0, +) ?? 0
        let deductionsSum = response.deductions?.values.reduce(0, +) ?? 0

        // Fundamental equation: gross - deductions = net
        let fundamentalError = abs((gross - deductions) - net)

        // Earnings sum vs grossPay
        let earningsError = gross > 0 ? abs(earningsSum - gross) / gross : 0

        // Deductions sum vs totalDeductions
        let deductionsError = deductions > 0 ? abs(deductionsSum - deductions) / deductions : 0

        // Consider reconciled if fundamental equation is within 1% and sums are within 5%
        let fundamentalOK = gross > 0 ? (fundamentalError / gross) < 0.01 : true
        let earningsOK = earningsError < 0.05
        let deductionsOK = deductionsError < 0.05
        let deductionsLessThanGross = deductions < gross

        return LLMReconciliationResult(
            isReconciled: fundamentalOK && earningsOK && deductionsOK && deductionsLessThanGross,
            grossPay: gross,
            totalDeductions: deductions,
            netRemittance: net,
            earningsSum: earningsSum,
            deductionsSum: deductionsSum,
            fundamentalEquationError: fundamentalError,
            earningsSumError: earningsError,
            deductionsSumError: deductionsError
        )
    }

    // MARK: - Line Item Validation

    /// Known code typical ranges for validation
    /// Relaxed ranges to accommodate arrears, part-month payments, and lower ranks
    private static let knownCodeRanges: [String: ClosedRange<Double>] = [
        "BPAY": 15000...300000,      // Basic Pay (wider for all ranks)
        "DA": 50...150000,           // Dearness Allowance (allows small arrears)
        "MSP": 500...30000,          // Military Service Pay (wider for all ranks)
        "TPAL": 50...10000,          // Transport Allowance (allows small values)
        "HRA": 500...80000,          // House Rent Allowance (wider range)
        "DSOP": 100...50000,         // DSOP Fund Subscription
        "AGIF": 500...30000,         // AGIF
        "ITAX": 0...200000           // Income Tax (higher for senior officers)
    ]

    /// Validates line items for common issues
    /// - Parameters:
    ///   - earnings: Earnings dictionary
    ///   - deductions: Deductions dictionary
    ///   - grossPay: Total gross pay
    /// - Returns: Array of validation warnings
    static func validateLineItems(
        earnings: [String: Double],
        deductions: [String: Double],
        grossPay: Double
    ) -> [String] {
        var warnings: [String] = []

        // Check 1: No single line item should exceed grossPay
        for (key, value) in earnings {
            if value > grossPay && grossPay > 0 {
                warnings.append("Earning '\(key)' (\(value)) exceeds grossPay (\(grossPay))")
            }
        }

        // Check 2: Filter zero-value items (noise)
        let zeroEarnings = earnings.filter { $0.value == 0 }.count
        let zeroDeductions = deductions.filter { $0.value == 0 }.count
        if zeroEarnings > 3 {
            warnings.append("Many zero-value earnings (\(zeroEarnings)) - possible extraction noise")
        }
        if zeroDeductions > 3 {
            warnings.append("Many zero-value deductions (\(zeroDeductions)) - possible extraction noise")
        }

        // Check 3: Detect potential duplicates (same amount in earnings and deductions)
        let earningAmounts = Set(earnings.values.filter { $0 > 1000 })
        let deductionAmounts = Set(deductions.values.filter { $0 > 1000 })
        let duplicates = earningAmounts.intersection(deductionAmounts)
        if !duplicates.isEmpty {
            warnings.append("Same amounts appear in both earnings and deductions: \(duplicates)")
        }

        // Check 4: Known code range validation
        let allItems = earnings.merging(deductions) { _, new in new }
        for (code, value) in allItems {
            if let range = knownCodeRanges[code.uppercased()], !range.contains(value) && value > 0 {
                warnings.append("'\(code)' value (\(Int(value))) outside typical range \(Int(range.lowerBound))-\(Int(range.upperBound))")
            }
        }

        return warnings
    }

    /// Removes zero-value entries from dictionary
    static func removeZeroValues(_ items: [String: Double]) -> [String: Double] {
        return items.filter { $0.value != 0 }
    }
}

