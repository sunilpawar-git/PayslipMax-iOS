import CoreGraphics
import Foundation
@testable import PayslipMax

/// A PII-free, pre-baked `[PositionalElement]` officer slip — real columnar geometry
/// (credit/debit label + amount X-bands from the plan's coordinate table), synthetic
/// financial values — paired with its reconciliation oracle.
///
/// Lets the calibration → pairing → totals-semantics path be exercised in CI without
/// real PDFs or `characterBounds`. The element types (`.label` / `.value`) are assigned
/// exactly as the production `CGPDFTokenExtractor` would, via `isAmount`.
struct PositionalFixture {
    let label: String
    let elements: [PositionalElement]
    let expectedEarnings: [String: Double]
    let expectedDeductions: [String: Double]
    let expectedGrossPay: Double
    let expectedTotalDeductions: Double
    let expectedNetRemittance: Double

    var expectedEarningsAmounts: [Double] { expectedEarnings.values.sorted() }
    var expectedDeductionAmounts: [Double] { expectedDeductions.values.sorted() }
}

/// Builds positional elements that mirror `CGPDFTokenExtractor`'s output.
enum ColumnarFixture {
    /// One token at a baseline-left origin; classified `.value`/`.label` by `isAmount`.
    static func el(_ text: String, x: CGFloat, y: CGFloat) -> PositionalElement {
        PositionalElement(
            text: text,
            bounds: CGRect(x: x, y: y, width: max(CGFloat(text.count) * 5, 1), height: 10),
            type: CGPDFTokenExtractor.isAmount(text) ? .value : .label,
            confidence: 1.0,
            fontSize: 10,
            pageIndex: 1
        )
    }
}

/// The four column X-anchors for a layout; emits side-by-side credit/debit rows.
struct ColumnLayout {
    let creditLabelX: CGFloat
    let creditAmountX: CGFloat
    let debitLabelX: CGFloat
    let debitAmountX: CGFloat

    /// A row with an optional credit `(label, amount)` and/or debit `(label, amount)`.
    func row(
        y: CGFloat,
        credit: (String, String)? = nil,
        debit: (String, String)? = nil
    ) -> [PositionalElement] {
        var elements: [PositionalElement] = []
        if let credit {
            elements.append(ColumnarFixture.el(credit.0, x: creditLabelX, y: y))
            elements.append(ColumnarFixture.el(credit.1, x: creditAmountX, y: y))
        }
        if let debit {
            elements.append(ColumnarFixture.el(debit.0, x: debitLabelX, y: y))
            elements.append(ColumnarFixture.el(debit.1, x: debitAmountX, y: y))
        }
        return elements
    }
}
