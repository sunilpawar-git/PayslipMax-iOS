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
        guard let totals = ColumnarRows.totalsRow(rows) else {
            return nil
        }
        let amounts = ColumnarRows.values(totals).sorted { $0.bounds.minX < $1.bounds.minX }
        guard amounts.count >= 2 else {
            return nil
        }
        return ColumnBands(
            creditAmountX: amounts[0].bounds.minX,
            debitAmountX: amounts[1].bounds.minX,
            narrativeCutoffX: narrativeCutoff(elements: elements)
        )
    }

    /// X of the narrative-column header if present, else "no cutoff".
    private func narrativeCutoff(elements: [PositionalElement]) -> CGFloat {
        elements.first { OfficerColumnarLabels.isNarrativeHeader($0.text) }?.bounds.minX
            ?? .greatestFiniteMagnitude
    }
}
