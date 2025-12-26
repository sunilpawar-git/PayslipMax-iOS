//
//  PayslipSanityCheckValidator.swift
//  PayslipMax
//
//  Rule-based sanity checking for LLM-parsed payslips
//

import Foundation
import OSLog

/// Result of sanity check validation
struct SanityCheckResult {
    let issues: [SanityCheckIssue]
    let confidenceAdjustment: Double  // Penalty to apply to confidence score (0.0 to -1.0)
    let severity: SanityCheckSeverity

    var isValid: Bool {
        return severity != .critical
    }

    var hasConcerns: Bool {
        return !issues.isEmpty
    }
}

enum SanityCheckSeverity {
    case none       // No issues
    case minor      // Small discrepancies, acceptable
    case warning    // Noticeable issues, should review
    case critical   // Major problems, likely parsing error
}

struct SanityCheckIssue {
    let code: String
    let description: String
    let severity: SanityCheckSeverity
    let confidencePenalty: Double
}

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

        // Check 1: Deductions should be less than earnings
        issues.append(contentsOf: checkDeductionsVsEarnings(
            totalDeductions: totalDeductions,
            grossPay: grossPay
        ))

        // Check 2: Net reconciliation (Net = Gross - Deductions)
        issues.append(contentsOf: checkNetReconciliation(
            grossPay: grossPay,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance
        ))

        // Check 3: Totals match sum of line items
        issues.append(contentsOf: checkTotalsMatchLineItems(
            earnings: earnings,
            deductions: deductions,
            grossPay: grossPay,
            totalDeductions: totalDeductions
        ))

        // Check 4: Mandatory components present
        issues.append(contentsOf: checkMandatoryComponents(
            earnings: earnings,
            deductions: deductions
        ))

        // Check 5: Suspicious deduction keys
        issues.append(contentsOf: checkSuspiciousKeys(deductions: deductions))

        // Check 6: Reasonable value ranges
        issues.append(contentsOf: checkValueRanges(
            grossPay: grossPay,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance
        ))

        // Calculate overall severity and confidence adjustment
        let severity = calculateSeverity(issues: issues)
        let confidenceAdjustment = calculateConfidenceAdjustment(issues: issues)

        // Log results
        if !issues.isEmpty {
            logger.info("Sanity check found \(issues.count) issue(s), severity: \(String(describing: severity))")
            for issue in issues {
                logger.debug("  • [\(issue.code)] \(issue.description)")
            }
        } else {
            logger.info("✓ Sanity check passed - no issues found")
        }

        return SanityCheckResult(
            issues: issues,
            confidenceAdjustment: confidenceAdjustment,
            severity: severity
        )
    }

    // MARK: - Individual Checks

    private func checkDeductionsVsEarnings(totalDeductions: Double, grossPay: Double) -> [SanityCheckIssue] {
        guard grossPay > 0 else { return [] }

        if totalDeductions > grossPay {
            let ratio = totalDeductions / grossPay
            return [SanityCheckIssue(
                code: "DEDUCTIONS_EXCEED_EARNINGS",
                description: "Deductions (₹\(Int(totalDeductions))) exceed earnings (₹\(Int(grossPay))) by \(String(format: "%.0f%%", (ratio - 1.0) * 100))",
                severity: .critical,
                confidencePenalty: -0.4
            )]
        }

        return []
    }

    private func checkNetReconciliation(grossPay: Double, totalDeductions: Double, netRemittance: Double) -> [SanityCheckIssue] {
        guard grossPay > 0 else { return [] }

        let expectedNet = grossPay - totalDeductions
        let error = abs(expectedNet - netRemittance)
        let errorPercent = error / grossPay

        if errorPercent > 0.05 {
            // >5% error
            return [SanityCheckIssue(
                code: "NET_RECONCILIATION_FAILED",
                description: "Net pay (₹\(Int(netRemittance))) doesn't match Gross - Deductions (₹\(Int(expectedNet))), error: \(String(format: "%.1f%%", errorPercent * 100))",
                severity: .warning,
                confidencePenalty: -0.2
            )]
        } else if errorPercent > 0.01 {
            // 1-5% error
            return [SanityCheckIssue(
                code: "NET_RECONCILIATION_MINOR",
                description: "Net pay has minor reconciliation error: \(String(format: "%.1f%%", errorPercent * 100))",
                severity: .minor,
                confidencePenalty: -0.05
            )]
        }

        return []
    }

    private func checkTotalsMatchLineItems(earnings: [String: Double], deductions: [String: Double], grossPay: Double, totalDeductions: Double) -> [SanityCheckIssue] {
        var issues: [SanityCheckIssue] = []

        let earningsSum = earnings.values.reduce(0, +)
        let deductionsSum = deductions.values.reduce(0, +)

        // Check earnings total
        if grossPay > 0 {
            let earningsError = abs(earningsSum - grossPay) / grossPay
            if earningsError > 0.05 {
                issues.append(SanityCheckIssue(
                    code: "EARNINGS_TOTAL_MISMATCH",
                    description: "Sum of earnings (₹\(Int(earningsSum))) doesn't match total (₹\(Int(grossPay))), error: \(String(format: "%.1f%%", earningsError * 100))",
                    severity: .warning,
                    confidencePenalty: -0.1
                ))
            }
        }

        // Check deductions total
        if totalDeductions > 0 {
            let deductionsError = abs(deductionsSum - totalDeductions) / totalDeductions
            if deductionsError > 0.05 {
                issues.append(SanityCheckIssue(
                    code: "DEDUCTIONS_TOTAL_MISMATCH",
                    description: "Sum of deductions (₹\(Int(deductionsSum))) doesn't match total (₹\(Int(totalDeductions))), error: \(String(format: "%.1f%%", deductionsError * 100))",
                    severity: .warning,
                    confidencePenalty: -0.1
                ))
            }
        }

        return issues
    }

    private func checkMandatoryComponents(earnings: [String: Double], deductions: [String: Double]) -> [SanityCheckIssue] {
        var issues: [SanityCheckIssue] = []

        // Check for BPAY (Basic Pay) - should be present in most payslips
        let hasBPAY = earnings.keys.contains { $0.uppercased().contains("BPAY") || $0.uppercased().contains("BASIC PAY") }
        if !hasBPAY {
            issues.append(SanityCheckIssue(
                code: "MISSING_BPAY",
                description: "Basic Pay (BPAY) not found in earnings",
                severity: .minor,
                confidencePenalty: -0.05
            ))
        }

        return issues
    }

    private func checkSuspiciousKeys(deductions: [String: Double]) -> [SanityCheckIssue] {
        var issues: [SanityCheckIssue] = []

        let suspiciousKeywords = ["total", "balance", "released", "refund", "recovery", "advance", "credit balance"]

        for (key, value) in deductions {
            let lowercaseKey = key.lowercased()
            if let suspiciousWord = suspiciousKeywords.first(where: { lowercaseKey.contains($0) }) {
                issues.append(SanityCheckIssue(
                    code: "SUSPICIOUS_DEDUCTION_KEY",
                    description: "Suspicious deduction key: '\(key)' (₹\(Int(value))) contains '\(suspiciousWord)'",
                    severity: .warning,
                    confidencePenalty: -0.15
                ))
            }
        }

        return issues
    }

    private func checkValueRanges(grossPay: Double, totalDeductions: Double, netRemittance: Double) -> [SanityCheckIssue] {
        var issues: [SanityCheckIssue] = []

        // Gross pay should be reasonable (>= 10,000 for military payslips)
        if grossPay < 10000 && grossPay > 0 {
            issues.append(SanityCheckIssue(
                code: "GROSS_PAY_TOO_LOW",
                description: "Gross pay (₹\(Int(grossPay))) seems unusually low for a military payslip",
                severity: .minor,
                confidencePenalty: -0.05
            ))
        }

        // Net pay should be positive
        if netRemittance < 0 {
            issues.append(SanityCheckIssue(
                code: "NEGATIVE_NET_PAY",
                description: "Net remittance is negative (₹\(Int(netRemittance)))",
                severity: .critical,
                confidencePenalty: -0.3
            ))
        }

        return issues
    }

    // MARK: - Severity and Confidence Calculation

    private func calculateSeverity(issues: [SanityCheckIssue]) -> SanityCheckSeverity {
        if issues.isEmpty {
            return .none
        }

        let hasCritical = issues.contains { $0.severity == .critical }
        if hasCritical {
            return .critical
        }

        let warningCount = issues.filter { $0.severity == .warning }.count
        if warningCount >= 2 {
            return .warning
        } else if warningCount == 1 {
            return .warning
        }

        return .minor
    }

    private func calculateConfidenceAdjustment(issues: [SanityCheckIssue]) -> Double {
        let totalPenalty = issues.reduce(0.0) { $0 + $1.confidencePenalty }
        // Cap penalty at -0.5 (maximum 50% confidence reduction)
        return max(totalPenalty, -0.5)
    }
}
