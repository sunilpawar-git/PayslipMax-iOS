import Foundation
import OSLog

/// Encapsulates heuristic checks for hybrid parsing decisions.
struct HybridParsingHeuristics {
    private let logger: os.Logger
    private let diagnosticsService: ParsingDiagnosticsServiceProtocol

    init(logger: os.Logger, diagnosticsService: ParsingDiagnosticsServiceProtocol) {
        self.logger = logger
        self.diagnosticsService = diagnosticsService
    }

    // MARK: - Public API

    func guardedFallbackReason(for item: PayslipItem) -> String? {
        // Require anchors (credits/debits) to be present; otherwise guard is not meaningful
        let anchorsPresent = item.metadata["anchors.present"] == "true" || item.credits > 0 || item.debits > 0
        guard anchorsPresent else { return nil }

        // Mandatory component checks (case-insensitive)
        let hasBPAY = containsKey(in: item.earnings, matching: ["BPAY", "Basic Pay"])
        let hasITAX = containsKey(in: item.deductions, matching: ["ITAX", "Income Tax"])
        if !hasBPAY || !hasITAX {
            return "Mandatory components missing"
        }

        // Totals mismatch (>5%) using anchors as ground truth
        let earningsSum = item.earnings.values.reduce(0, +)
        let deductionsSum = item.deductions.values.reduce(0, +)

        let earningsError = item.credits > 0 ? abs(item.credits - earningsSum) / item.credits : 0
        let deductionsError = item.debits > 0 ? abs(item.debits - deductionsSum) / item.debits : 0

        if max(earningsError, deductionsError) > 0.05 {
            return "Totals mismatch >5%"
        }

        // Net was derived (no explicit net in text)
        let netDerived = item.metadata["anchors.isNetDerived"]?.lowercased() == "true"
        if netDerived {
            return "Net derived from anchors"
        }

        return nil
    }

    func calculateParsingConfidence(_ item: PayslipItem) -> Double {
        var confidence = 1.0

        // === Factor 1: Mandatory Components (up to -0.4) ===
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

        // === Factor 2: Totals Match (up to -0.3) ===
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
            let penalty = maxErrorPercent * 6  // 1% = -0.06, 5% = -0.30
            confidence -= penalty
            logger.debug("Confidence penalty: Totals \(String(format: "%.1f", maxErrorPercent * 100))% off (-\(String(format: "%.2f", penalty)))")

            diagnosticsService.recordNearMissTotals(
                earningsExpected: item.credits,
                earningsActual: earningsSum,
                deductionsExpected: item.debits,
                deductionsActual: deductionsSum
            )
        }

        // === Factor 3: Component Count (up to -0.2) ===
        let totalComponents = item.earnings.count + item.deductions.count

        if totalComponents < 3 {
            confidence -= 0.2
            logger.debug("Confidence penalty: Only \(totalComponents) components (-0.2)")
        } else if totalComponents < 6 {
            confidence -= 0.1
            logger.debug("Confidence penalty: Only \(totalComponents) components (-0.1)")
        }

        // === Factor 4: Key Component Presence (up to -0.1) ===
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

    // MARK: - Helpers

    private func containsKey(in dict: [String: Double], matching keys: [String]) -> Bool {
        let loweredKeys = keys.map { $0.lowercased() }
        return dict.keys.contains { loweredKeys.contains($0.lowercased()) }
    }

    func recordMandatoryDiagnosticsIfNeeded(for item: PayslipItem) {
        if !containsKey(in: item.earnings, matching: ["BPAY", "Basic Pay"]) {
            diagnosticsService.recordMandatoryComponentMissing("BPAY")
        }
        if !containsKey(in: item.deductions, matching: ["ITAX", "Income Tax"]) {
            diagnosticsService.recordMandatoryComponentMissing("ITAX")
        }
    }
}
