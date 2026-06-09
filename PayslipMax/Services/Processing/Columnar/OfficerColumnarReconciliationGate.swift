import Foundation

/// The hard acceptance gate for the position-aware columnar parse.
///
/// Accepts a result only when it reconciles three ways within ±1 rupee:
/// - `Σ earnings ≈ grossPay`
/// - `Σ deductions ≈ totalDeductions` (the *true* deductions per the resolved template)
/// - `grossPay − totalDeductions ≈ netRemittance`
///
/// A mis-paired or mis-calibrated parse fails at least one check and is rejected, so the
/// pipeline falls back to the existing cascade rather than ever shipping wrong data.
/// Purely arithmetic — no vocabulary, no pay-code knowledge.
final class OfficerColumnarReconciliationGate {
    /// Whole-rupee tolerance (matches the extractor's totals tolerance).
    static let tolerance: Double = 1.0

    /// `true` iff the result reconciles on all three checks.
    func accept(_ result: OfficerColumnarResult) -> Bool {
        let earningsSum = result.earnings.values.reduce(0, +)
        let deductionsSum = result.deductions.values.reduce(0, +)
        return close(earningsSum, result.grossPay)
            && close(deductionsSum, result.totalDeductions)
            && close(result.grossPay - result.totalDeductions, result.netRemittance)
    }

    private func close(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) <= Self.tolerance
    }
}
