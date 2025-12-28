//
//  SanityCheckRules.swift
//  PayslipMax
//
//  Individual sanity check rules for payslip validation
//

import Foundation

/// Contains individual sanity check rules
enum SanityCheckRules {

    /// Check: FUNDAMENTAL EQUATION - Most critical check
    /// Ensures: grossPay - totalDeductions = netRemittance
    static func checkFundamentalEquation(
        grossPay: Double,
        totalDeductions: Double,
        netRemittance: Double
    ) -> [SanityCheckIssue] {
        guard grossPay > 0 else { return [] }

        let expectedNet = grossPay - totalDeductions
        let error = abs(expectedNet - netRemittance)
        let errorPercent = error / grossPay

        if errorPercent > ValidationThresholds.fundamentalEquationTolerance {
            let errStr = String(format: "%.1f%%", errorPercent * 100)
            let desc = "Fundamental equation: \(Int(grossPay)) - " +
                "\(Int(totalDeductions)) = \(Int(expectedNet)), " +
                "net = \(Int(netRemittance)) (err: \(errStr))"
            return [SanityCheckIssue(
                code: "FUNDAMENTAL_EQUATION_FAILED",
                description: desc,
                severity: errorPercent > 0.05 ? .critical : .warning,
                confidencePenalty: ValidationThresholds.fundamentalEquationPenalty
            )]
        }
        return []
    }

    /// Check: Net remittance should be positive and less than grossPay
    static func checkNetRemittanceReasonable(
        netRemittance: Double,
        grossPay: Double
    ) -> [SanityCheckIssue] {
        var issues: [SanityCheckIssue] = []

        if netRemittance <= 0 && grossPay > 0 {
            issues.append(SanityCheckIssue(
                code: "NET_REMITTANCE_NOT_POSITIVE",
                description: "Net remittance (₹\(Int(netRemittance))) should be positive",
                severity: .critical,
                confidencePenalty: ValidationThresholds.criticalPenalty
            ))
        }

        if netRemittance > grossPay && grossPay > 0 {
            issues.append(SanityCheckIssue(
                code: "NET_REMITTANCE_EXCEEDS_GROSS",
                description: "Net remittance (₹\(Int(netRemittance))) exceeds grossPay (₹\(Int(grossPay)))",
                severity: .critical,
                confidencePenalty: ValidationThresholds.criticalPenalty
            ))
        }
        return issues
    }

    /// Check: Deductions should be less than earnings
    static func checkDeductionsVsEarnings(
        totalDeductions: Double,
        grossPay: Double
    ) -> [SanityCheckIssue] {
        guard grossPay > 0 else { return [] }

        if totalDeductions > grossPay {
            let ratio = totalDeductions / grossPay
            return [SanityCheckIssue(
                code: "DEDUCTIONS_EXCEED_EARNINGS",
                description: "Deductions (₹\(Int(totalDeductions))) exceed earnings (₹\(Int(grossPay))) by \(String(format: "%.0f%%", (ratio - 1.0) * 100))",
                severity: .critical,
                confidencePenalty: ValidationThresholds.criticalPenalty
            )]
        }
        return []
    }

    /// Check: Net reconciliation (Net = Gross - Deductions)
    static func checkNetReconciliation(
        grossPay: Double,
        totalDeductions: Double,
        netRemittance: Double
    ) -> [SanityCheckIssue] {
        guard grossPay > 0 else { return [] }

        let expectedNet = grossPay - totalDeductions
        let error = abs(expectedNet - netRemittance)
        let errorPercent = error / grossPay

        if errorPercent > ValidationThresholds.majorErrorPercent {
            return [SanityCheckIssue(
                code: "NET_RECONCILIATION_FAILED",
                description: "Net (₹\(Int(netRemittance))) ≠ Gross - Deductions (₹\(Int(expectedNet))), error: \(String(format: "%.1f%%", errorPercent * 100))",
                severity: .warning,
                confidencePenalty: ValidationThresholds.netReconciliationPenalty
            )]
        } else if errorPercent > ValidationThresholds.minorErrorPercent {
            return [SanityCheckIssue(
                code: "NET_RECONCILIATION_MINOR",
                description: "Net pay has minor reconciliation error: \(String(format: "%.1f%%", errorPercent * 100))",
                severity: .minor,
                confidencePenalty: ValidationThresholds.minorConfidencePenalty
            )]
        }
        return []
    }

    /// Check: Totals match sum of line items
    static func checkTotalsMatchLineItems(
        earnings: [String: Double],
        deductions: [String: Double],
        grossPay: Double,
        totalDeductions: Double
    ) -> [SanityCheckIssue] {
        var issues: [SanityCheckIssue] = []

        let earningsSum = earnings.values.reduce(0, +)
        let deductionsSum = deductions.values.reduce(0, +)

        // Check earnings total
        if grossPay > 0 {
            let earningsError = abs(earningsSum - grossPay) / grossPay
            if earningsError > ValidationThresholds.lineItemSumTolerance {
                issues.append(SanityCheckIssue(
                    code: "EARNINGS_SUM_MISMATCH",
                    description: "Earnings sum (₹\(Int(earningsSum))) ≠ grossPay (₹\(Int(grossPay))), error: \(String(format: "%.1f%%", earningsError * 100))",
                    severity: .warning,
                    confidencePenalty: ValidationThresholds.earningsSumMismatchPenalty
                ))
            }
        }

        // Check deductions total
        if totalDeductions > 0 {
            let deductionsError = abs(deductionsSum - totalDeductions) / totalDeductions
            if deductionsError > ValidationThresholds.lineItemSumTolerance {
                issues.append(SanityCheckIssue(
                    code: "DEDUCTIONS_SUM_MISMATCH",
                    description: "Deductions sum (₹\(Int(deductionsSum))) ≠ totalDeductions (₹\(Int(totalDeductions))), error: \(String(format: "%.1f%%", deductionsError * 100))",
                    severity: .warning,
                    confidencePenalty: ValidationThresholds.deductionsSumMismatchPenalty
                ))
            }
        }
        return issues
    }

    /// Check: Mandatory components present
    static func checkMandatoryComponents(
        earnings: [String: Double],
        deductions: [String: Double]
    ) -> [SanityCheckIssue] {
        var issues: [SanityCheckIssue] = []

        let hasBPAY = earnings.keys.contains {
            $0.uppercased().contains("BPAY") || $0.uppercased().contains("BASIC PAY")
        }
        if !hasBPAY {
            issues.append(SanityCheckIssue(
                code: "MISSING_BPAY",
                description: "Basic Pay (BPAY) not found in earnings",
                severity: .minor,
                confidencePenalty: ValidationThresholds.minorConfidencePenalty
            ))
        }
        return issues
    }

    /// Check: Suspicious deduction keys
    static func checkSuspiciousKeys(deductions: [String: Double]) -> [SanityCheckIssue] {
        var issues: [SanityCheckIssue] = []

        for (key, value) in deductions {
            if let suspiciousWord = SuspiciousKeywordsConfig.findSuspiciousWord(in: key) {
                issues.append(SanityCheckIssue(
                    code: "SUSPICIOUS_DEDUCTION_KEY",
                    description: "Suspicious key: '\(key)' (₹\(Int(value))) contains '\(suspiciousWord)'",
                    severity: .warning,
                    confidencePenalty: ValidationThresholds.suspiciousKeyPenalty
                ))
            }
        }
        return issues
    }

    /// Check: Reasonable value ranges
    static func checkValueRanges(
        grossPay: Double,
        totalDeductions: Double,
        netRemittance: Double
    ) -> [SanityCheckIssue] {
        var issues: [SanityCheckIssue] = []

        if grossPay < ValidationThresholds.minimumGrossPay && grossPay > 0 {
            issues.append(SanityCheckIssue(
                code: "GROSS_PAY_TOO_LOW",
                description: "Gross pay (₹\(Int(grossPay))) seems low for military payslip",
                severity: .minor,
                confidencePenalty: ValidationThresholds.minorConfidencePenalty
            ))
        }

        if netRemittance < 0 {
            issues.append(SanityCheckIssue(
                code: "NEGATIVE_NET_PAY",
                description: "Net remittance is negative (₹\(Int(netRemittance)))",
                severity: .critical,
                confidencePenalty: ValidationThresholds.negativeNetPayPenalty
            ))
        }
        return issues
    }
}

