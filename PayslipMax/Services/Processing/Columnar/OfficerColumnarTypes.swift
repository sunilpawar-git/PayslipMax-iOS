import CoreGraphics
import Foundation

// swiftlint:disable no_hardcoded_strings
// The string literals here are structural PCDA(O) anchor keywords (TOTAL CREDIT,
// GROSS PAY, REMITTANCE, …) used to recognize totals/narrative rows — content
// markers fixed by the slip layout, not user-facing copy.

/// The amount-column X anchors derived from the totals row, plus the X past which
/// tokens belong to the transaction-narrative column and must be ignored.
struct ColumnBands {
    /// X of the credit (earnings) amount column.
    let creditAmountX: CGFloat
    /// X of the debit (deductions) amount column.
    let debitAmountX: CGFloat
    /// Tokens with `minX >= narrativeCutoffX` are narrative noise and are dropped.
    /// `.greatestFiniteMagnitude` when the layout has no narrative column.
    let narrativeCutoffX: CGFloat
}

/// Which printed-totals template a slip uses.
enum OfficerTotalsTemplate {
    /// Old layout: printed `Total Debit ≈ Total Credit` (remittance folded into debits);
    /// the true deductions are `Total Credit − REMITTANCE`.
    case oldFolded
    /// New layout: the right-column total is already the true deductions.
    case newDirect
}

/// The deterministic, vocabulary-free output of the columnar extractor. `earnings` /
/// `deductions` carry **verbatim** PDF labels (v1); reconciliation — not vocabulary —
/// is the acceptance bar (enforced by the Phase 3 gate).
struct OfficerColumnarResult {
    let earnings: [String: Double]
    let deductions: [String: Double]
    let grossPay: Double
    /// True deductions (per the resolved template), not the folded printed figure.
    let totalDeductions: Double
    let netRemittance: Double
    let template: OfficerTotalsTemplate
}

/// Structural-label recognizers for totals / remittance / narrative rows. These match
/// **layout anchors**, never pay codes — the line-item path stays vocabulary-free.
enum OfficerColumnarLabels {
    static func isCreditTotal(_ raw: String) -> Bool {
        let text = raw.uppercased()
        return text.contains("GROSS PAY") || text.contains("TOTAL CREDIT")
    }

    static func isDebitTotal(_ raw: String) -> Bool {
        let text = raw.uppercased()
        return text.contains("TOTAL DEDUCTION") || text.contains("TOTAL DEBIT")
    }

    static func isRemittance(_ raw: String) -> Bool {
        raw.uppercased().contains("REMITTANCE")
    }

    /// The "DETAILS OF TRANSACTIONS" header that anchors the narrative column.
    static func isNarrativeHeader(_ raw: String) -> Bool {
        raw.uppercased().contains("TRANSACTION")
    }

    /// True for any non-line-item row (totals, remittance, narrative or column header)
    /// that must be excluded from pairing.
    static func isStructural(_ raw: String) -> Bool {
        if isCreditTotal(raw) || isDebitTotal(raw) || isRemittance(raw) || isNarrativeHeader(raw) {
            return true
        }
        return headerKeywords.contains(raw.uppercased())
    }

    private static let headerKeywords = ["DESCRIPTION", "AMOUNT", "EARNINGS", "DEDUCTIONS", "DETAILS"]

    /// Parses a numeric token (commas allowed) into a rupee amount, else `nil`.
    static func amount(_ raw: String) -> Double? {
        Double(raw.replacingOccurrences(of: ",", with: ""))
    }
}

/// Row-level accessors shared by the calibrator, pairer and totals reader.
enum ColumnarRows {
    /// Value (amount) elements in a row.
    static func values(_ row: TableRow) -> [PositionalElement] {
        row.elements.filter { $0.type == .value }
    }

    /// Label elements in a row.
    static func labels(_ row: TableRow) -> [PositionalElement] {
        row.elements.filter { $0.type == .label }
    }

    /// The single totals row — the one carrying both a credit-total and a debit-total label.
    static func totalsRow(_ rows: [TableRow]) -> TableRow? {
        rows.first { row in
            row.elements.contains { OfficerColumnarLabels.isCreditTotal($0.text) }
                && row.elements.contains { OfficerColumnarLabels.isDebitTotal($0.text) }
        }
    }
}

// swiftlint:enable no_hardcoded_strings
