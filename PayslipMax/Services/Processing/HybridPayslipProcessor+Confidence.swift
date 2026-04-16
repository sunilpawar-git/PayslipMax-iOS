import Foundation
import OSLog

extension HybridPayslipProcessor {

    func calculateParsingConfidence(_ item: PayslipItem) -> Double {
        var confidence = 1.0

        let hasBPAY = item.earnings["BPAY"] != nil || item.earnings["Basic Pay"] != nil
        let hasDSOP = item.deductions["DSOP"] != nil || item.deductions["AFPP Fund"] != nil

        if !hasBPAY {
            logger.debug("Confidence penalty: Missing BPAY (-0.2)")
            diagnosticsService.recordMandatoryComponentMissing("BPAY")
            confidence -= 0.2
        }

        if !hasDSOP {
            logger.debug("Confidence penalty: Missing DSOP (-0.2)")
            diagnosticsService.recordMandatoryComponentMissing("DSOP")
            confidence -= 0.2
        }

        let earningsSum = item.earnings.values.reduce(0, +)
        let deductionsSum = item.deductions.values.reduce(0, +)

        let grossDiff = abs(earningsSum - item.credits)
        let deductionDiff = abs(deductionsSum - item.debits)

        let grossErrorPercent = item.credits > 0 ? (grossDiff / item.credits) : 0
        let deductionErrorPercent = item.debits > 0 ? (deductionDiff / item.debits) : 0
        let maxErrorPercent = max(grossErrorPercent, deductionErrorPercent)

        if maxErrorPercent > 0.05 {
            confidence -= 0.3
            logger.debug("Confidence penalty: Totals >5% off (-0.3)")
        } else if maxErrorPercent > 0.01 {
            let penalty = maxErrorPercent * 6
            confidence -= penalty
            logger.debug("Confidence penalty: Totals \(String(format: "%.1f", maxErrorPercent * 100))% off (-\(String(format: "%.2f", penalty)))")

            diagnosticsService.recordNearMissTotals(
                earningsExpected: item.credits,
                earningsActual: earningsSum,
                deductionsExpected: item.debits,
                deductionsActual: deductionsSum
            )
        }

        let totalComponents = item.earnings.count + item.deductions.count

        if totalComponents < 3 {
            confidence -= 0.2
            logger.debug("Confidence penalty: Only \(totalComponents) components (-0.2)")
        } else if totalComponents < 6 {
            confidence -= 0.1
            logger.debug("Confidence penalty: Only \(totalComponents) components (-0.1)")
        }

        let hasDA = item.earnings["DA"] != nil || item.earnings["Dearness Allowance"] != nil
        if !hasDA && item.credits > 50000 {
            confidence -= 0.05
            logger.debug("Confidence penalty: Missing DA on high-value payslip (-0.05)")
        }

        let hasTax = item.deductions["ITAX"] != nil || item.deductions["Income Tax"] != nil || item.deductions["IT"] != nil
        if !hasTax && item.credits > 100000 {
            confidence -= 0.05
            logger.debug("Confidence penalty: Missing ITAX on high-value payslip (-0.05)")
        }

        confidence = max(0.0, min(1.0, confidence))
        logger.debug("Final parsing confidence: \(String(format: "%.2f", confidence))")

        return confidence
    }
}
