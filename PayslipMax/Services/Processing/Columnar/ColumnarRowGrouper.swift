import CoreGraphics
import Foundation

/// Groups positional tokens into rows by **strict shared baseline Y**.
///
/// The columnar pipeline's invariant is "same printed baseline = same row". `RowAssociator`
/// instead applies multi-line-cell merging, which on heavy-narrative officer slips collapses
/// every line item — and the column header — into one giant row (so `isStructural` then
/// nukes the whole thing and no line items pair). Real PCDA(O) rows are ≥14 pt apart and
/// same-row tokens share a baseline within ~1 pt, so a tight bucket separates them cleanly
/// and deterministically.
enum ColumnarRowGrouper {
    /// Tokens whose baseline (`minY`) is within `tolerance` of an open bucket join it; a new
    /// bucket opens otherwise. Buckets are emitted top-to-bottom as `TableRow`s.
    static func group(_ elements: [PositionalElement], tolerance: CGFloat = 4) -> [TableRow] {
        var buckets: [(anchorY: CGFloat, items: [PositionalElement])] = []
        for element in elements.sorted(by: { $0.bounds.minY > $1.bounds.minY }) {
            let baseline = element.bounds.minY
            if let index = buckets.firstIndex(where: { abs($0.anchorY - baseline) <= tolerance }) {
                buckets[index].items.append(element)
            } else {
                buckets.append((baseline, [element]))
            }
        }
        return buckets.enumerated().map { index, bucket in
            TableRow(elements: bucket.items, rowIndex: index)
        }
    }
}
