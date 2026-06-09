import CoreGraphics
import Foundation

/// The raw printed totals read off the slip, before template resolution.
struct OfficerColumnarTotals {
    /// `Total Credit` / `Gross Pay`.
    let gross: Double
    /// The right-column total as printed (`Total Debit` on old slips, `Total Deductions`
    /// on new ones).
    let rightColumnTotal: Double
    /// `REMITTANCE` if printed as its own row — required only for the folded old layout.
    let remittance: Double?
}

/// Reads the printed totals from the structured rows and resolves which template the
/// slip uses, yielding the *true* deductions and net.
///
/// Old slips fold remittance into the printed `Total Debit` so it balances `Total
/// Credit`; the true deductions are `Gross − REMITTANCE`. New slips print the true
/// deductions directly. Detection is purely arithmetic (`rightColumnTotal ≈ gross`),
/// needing no vocabulary.
final class OfficerTotalsSemantics {
    /// Whole-rupee tolerance for the fold test.
    static let tolerance: Double = 1.0

    func read(rows: [TableRow]) -> OfficerColumnarTotals? {
        let amounts = ColumnarRows.totalsAmounts(rows)
        guard amounts.count >= 2,
              let gross = OfficerColumnarLabels.amount(amounts[0].text),
              let right = OfficerColumnarLabels.amount(amounts[1].text) else {
            return nil
        }
        return OfficerColumnarTotals(gross: gross, rightColumnTotal: right, remittance: remittance(rows))
    }

    /// The amount on the first row carrying a `REMITTANCE` label.
    private func remittance(_ rows: [TableRow]) -> Double? {
        for row in rows where row.elements.contains(where: { OfficerColumnarLabels.isRemittance($0.text) }) {
            if let value = ColumnarRows.values(row).first.flatMap({ OfficerColumnarLabels.amount($0.text) }) {
                return value
            }
        }
        return nil
    }

    func resolve(
        _ totals: OfficerColumnarTotals
    ) -> (template: OfficerTotalsTemplate, trueDeductions: Double, net: Double)? {
        if abs(totals.rightColumnTotal - totals.gross) <= Self.tolerance {
            guard let remit = totals.remittance else {
                return nil
            }
            return (.oldFolded, totals.gross - remit, remit)
        }
        return (.newDirect, totals.rightColumnTotal, totals.gross - totals.rightColumnTotal)
    }
}
