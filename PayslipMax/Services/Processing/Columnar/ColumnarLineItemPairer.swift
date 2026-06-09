import CoreGraphics
import Foundation

/// Pairs each row's amount tokens with their left-hand label and routes them to the
/// credit or debit dictionary by nearest column anchor — the core fix for the
/// reading-order mis-pairing (`BPAY (12A)` → `12`) that broke the regex path.
///
/// Per row: drop tokens past the narrative cutoff, then for every amount pick the
/// nearest label to its left and the column (credit/debit) whose anchor it sits closest
/// to. Credit-only and debit-only rows fall out naturally (a single amount). A label
/// appearing in both columns (e.g. `ETKT`) is unambiguous because each amount keeps its
/// own-side label. Structural rows (totals/remittance/headers) are skipped entirely.
final class ColumnarLineItemPairer {
    func pair(
        rows: [TableRow],
        bands: ColumnBands
    ) -> (earnings: [String: Double], deductions: [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        let totalsBlock = ColumnarRows.totalsBlockRowIndices(rows)
        let region = ColumnarRows.lineItemRegion(rows)
        for row in rows where !isStructural(row)
            && !totalsBlock.contains(row.rowIndex)
            && inRegion(row, region) {
            pair(row: row, bands: bands, earnings: &earnings, deductions: &deductions)
        }
        return (earnings, deductions)
    }

    /// True when `row` sits within the line-item band (or there is no band to enforce).
    private func inRegion(_ row: TableRow, _ region: (top: CGFloat, bottom: CGFloat)?) -> Bool {
        guard let region else {
            return true
        }
        return row.yPosition < region.top && row.yPosition > region.bottom
    }

    private func isStructural(_ row: TableRow) -> Bool {
        row.elements.contains { OfficerColumnarLabels.isStructural($0.text) }
    }

    private func pair(
        row: TableRow,
        bands: ColumnBands,
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) {
        let labels = ColumnarRows.labels(row)
            .filter { $0.bounds.minX < bands.narrativeCutoffX }
        let amounts = ColumnarRows.values(row)
            .filter { $0.bounds.minX < bands.narrativeCutoffX }

        for amount in amounts {
            guard let value = OfficerColumnarLabels.amount(amount.text),
                  let label = nearestLeftLabel(labels, before: amount.bounds.minX) else {
                continue
            }
            let toCredit = abs(amount.bounds.minX - bands.creditAmountX)
                <= abs(amount.bounds.minX - bands.debitAmountX)
            if toCredit {
                insert(label.text, value, into: &earnings)
            } else {
                insert(label.text, value, into: &deductions)
            }
        }
    }

    /// The label with the greatest X strictly left of `x` (the amount's own label).
    private func nearestLeftLabel(_ labels: [PositionalElement], before x: CGFloat) -> PositionalElement? {
        labels.filter { $0.bounds.minX < x }.max { $0.bounds.minX < $1.bounds.minX }
    }

    /// Inserts verbatim, disambiguating a repeated label so no value is silently lost.
    private func insert(_ key: String, _ value: Double, into dict: inout [String: Double]) {
        guard dict[key] != nil else {
            dict[key] = value
            return
        }
        var index = 2
        while dict["\(key) #\(index)"] != nil {
            index += 1
        }
        dict["\(key) #\(index)"] = value
    }
}
