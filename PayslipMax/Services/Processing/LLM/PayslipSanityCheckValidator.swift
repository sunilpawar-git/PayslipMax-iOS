//
//  PayslipSanityCheckValidator.swift
//  PayslipMax
//
//  Rule-based sanity checking for LLM-parsed payslips
//  Uses SanityCheckRules for individual validation checks
//

import Foundation
import OSLog

/// Validates payslip parsing results using rule-based checks
final class PayslipSanityCheckValidator {
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "SanityCheck")

    /// Performs comprehensive sanity checks on parsed payslip
    /// - Parameter response: The LLM response to validate
    /// - Returns: SanityCheckResult with issues and confidence adjustment
    func validate(_ response: LLMPayslipResponse) -> SanityCheckResult {
        var issues: [SanityCheckIssue] = []

        // Extract values
        let earnings = response.earnings ?? [:]
        let deductions = response.deductions ?? [:]
        let grossPay = response.grossPay ?? 0
        let totalDeductions = response.totalDeductions ?? 0
        let netRemittance = response.netRemittance ?? 0

        // Run all sanity checks using SanityCheckRules
        issues.append(contentsOf: SanityCheckRules.checkFundamentalEquation(
            grossPay: grossPay,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance
        ))

        issues.append(contentsOf: SanityCheckRules.checkDeductionsVsEarnings(
            totalDeductions: totalDeductions,
            grossPay: grossPay
        ))

        issues.append(contentsOf: SanityCheckRules.checkNetReconciliation(
            grossPay: grossPay,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance
        ))

        issues.append(contentsOf: SanityCheckRules.checkTotalsMatchLineItems(
            earnings: earnings,
            deductions: deductions,
            grossPay: grossPay,
            totalDeductions: totalDeductions
        ))

        issues.append(contentsOf: SanityCheckRules.checkMandatoryComponents(
            earnings: earnings,
            deductions: deductions
        ))

        issues.append(contentsOf: SanityCheckRules.checkSuspiciousKeys(deductions: deductions))

        issues.append(contentsOf: SanityCheckRules.checkValueRanges(
            grossPay: grossPay,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance
        ))

        issues.append(contentsOf: SanityCheckRules.checkNetRemittanceReasonable(
            netRemittance: netRemittance,
            grossPay: grossPay
        ))

        // Calculate overall severity and confidence adjustment
        let severity = calculateSeverity(issues: issues)
        let confidenceAdjustment = calculateConfidenceAdjustment(issues: issues)

        // Log results
        logResults(issues: issues, severity: severity)

        return SanityCheckResult(
            issues: issues,
            confidenceAdjustment: confidenceAdjustment,
            severity: severity
        )
    }

    // MARK: - Helpers

    private func logResults(issues: [SanityCheckIssue], severity: SanityCheckSeverity) {
        if !issues.isEmpty {
            logger.info("Sanity check found \(issues.count) issue(s), severity: \(String(describing: severity))")
            for issue in issues {
                logger.debug("  • [\(issue.code)] \(issue.description)")
            }
        } else {
            logger.info("✓ Sanity check passed - no issues found")
        }
    }

    private func calculateSeverity(issues: [SanityCheckIssue]) -> SanityCheckSeverity {
        if issues.isEmpty { return .none }
        if issues.contains(where: { $0.severity == .critical }) { return .critical }
        if issues.contains(where: { $0.severity == .warning }) { return .warning }
        return .minor
    }

    private func calculateConfidenceAdjustment(issues: [SanityCheckIssue]) -> Double {
        let totalPenalty = issues.reduce(0.0) { $0 + $1.confidencePenalty }
        return max(totalPenalty, ValidationThresholds.maxConfidencePenalty)
    }
}
