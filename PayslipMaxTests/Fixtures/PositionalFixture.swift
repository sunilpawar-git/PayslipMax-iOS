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

    /// Distinct row baselines (Y), top-down.
    var rowYs: [CGFloat] { Set(elements.map { $0.bounds.minY }).sorted(by: >) }

    /// Smallest gap between adjacent distinct rows. The integration fixture proved rows
    /// spaced ≤ `ColumnLayout.rowTolerance` collapse during `RowAssociator` clustering, so
    /// the Phase 5 corpus asserts every fixture clears it (`> rowTolerance`).
    var minRowGap: CGFloat {
        let baselines = rowYs
        guard baselines.count > 1 else {
            return .greatestFiniteMagnitude
        }
        return zip(baselines, baselines.dropFirst()).map { $0 - $1 }.min() ?? .greatestFiniteMagnitude
    }
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

    /// `RowAssociator`'s Y-band tolerance — rows closer than this merge into one.
    static let rowTolerance: CGFloat = 15
    /// Safe vertical pitch between stacked rows (> `rowTolerance`), so adjacent rows never
    /// collapse during clustering. The integration fixture used 24 after tol-15 bit it.
    static let safeRowPitch: CGFloat = 24

    /// One credit/debit line in a stacked block.
    struct Line {
        let credit: (String, String)?
        let debit: (String, String)?
        init(credit: (String, String)? = nil, debit: (String, String)? = nil) {
            self.credit = credit
            self.debit = debit
        }
    }

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

    /// Y for the `index`-th stacked row below `top`, at the safe pitch.
    func stackedY(_ index: Int, top: CGFloat) -> CGFloat {
        top - CGFloat(index) * Self.safeRowPitch
    }

    /// Vertically stacks `lines` from `top` at the safe pitch — guaranteeing
    /// `> rowTolerance` spacing structurally, so the corpus can't reintroduce the merge bug.
    func stack(from top: CGFloat = 400, _ lines: [Line]) -> [PositionalElement] {
        lines.enumerated().flatMap { index, line in
            row(y: stackedY(index, top: top), credit: line.credit, debit: line.debit)
        }
    }
}
