import CoreGraphics
import Foundation

/// Derives the credit/debit amount-column X anchors from the totals row, and the
/// narrative-column cutoff from the "DETAILS OF TRANSACTIONS" header.
///
/// The totals row is the exact, vocabulary-free anchor: `Gross Pay 275015@x242`
/// fixes the credit column, `Total Deductions 102029@x448` the debit column. Every
/// line-item amount is then assigned to a column by nearest anchor. Returns `nil`
/// when the totals row is absent or malformed, which makes the extractor fall back
/// to the existing pipeline.
final class ColumnBandCalibrator {
    /// - Parameters:
    ///   - rows: Clustered rows — used to locate the totals row for the amount anchors.
    ///   - elements: The raw, pre-clustering tokens — used for the narrative cutoff, which
    ///     is a geometric property and must survive row clustering (the lone narrative
    ///     header can be merged away by `RowAssociator`).
    func calibrate(rows: [TableRow], elements: [PositionalElement]) -> ColumnBands? {
        let amounts = ColumnarRows.totalsAmounts(rows)
        guard amounts.count >= 2 else {
            return nil
        }
        let creditX = amounts[0].bounds.minX
        let debitX = amounts[1].bounds.minX
        return ColumnBands(
            creditAmountX: creditX,
            debitAmountX: debitX,
            narrativeCutoffX: min(narrativeCutoff(elements: elements), geometricCutoff(creditX, debitX))
        )
    }

    /// X of the narrative-column header if present, else "no cutoff".
    private func narrativeCutoff(elements: [PositionalElement]) -> CGFloat {
        elements.first { OfficerColumnarLabels.isNarrativeHeader($0.text) }?.bounds.minX
            ?? .greatestFiniteMagnitude
    }

    /// A geometric narrative cutoff one-and-a-half column-widths right of the debit amount
    /// column. The new bilingual layout has no "DETAILS OF TRANSACTIONS" header to anchor on,
    /// yet still prints a transaction-narrative column far to the right (x ≈ 324/534); real
    /// line-item amounts never sit that far out, so this drops the narrative deterministically.
    private func geometricCutoff(_ creditX: CGFloat, _ debitX: CGFloat) -> CGFloat {
        debitX + 1.5 * max(debitX - creditX, 1)
    }
}
