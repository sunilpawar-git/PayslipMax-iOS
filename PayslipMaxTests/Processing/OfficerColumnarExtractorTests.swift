import CoreGraphics
@testable import PayslipMax
import XCTest

/// **Plan Phase 2 — calibration + pairing + totals semantics.**
///
/// Unit-level tests that drive the columnar components from hand-built `TableRow`s
/// (deterministic, no `RowAssociator`): the calibrator derives column anchors from the
/// totals row; the pairer routes amounts by nearest anchor (incl. the `ETKT`-both-columns
/// and narrative-drop cases); the semantics resolves the old/new totals templates.
final class OfficerColumnarExtractorTests: XCTestCase {
    private let calibrator = ColumnBandCalibrator()
    private let pairer = ColumnarLineItemPairer()
    private let semantics = OfficerTotalsSemantics()

    // MARK: - Calibration

    func test_calibrator_derivesAnchorsFromTotalsRow() {
        let elements = [el("Gross Pay", 94), el("275015", 237), el("Total Deductions", 300), el("102029", 452)]
        let bands = calibrator.calibrate(rows: [row(elements)], elements: elements)
        XCTAssertEqual(bands?.creditAmountX, 237)
        XCTAssertEqual(bands?.debitAmountX, 452)
        XCTAssertEqual(bands?.narrativeCutoffX, .greatestFiniteMagnitude)
    }

    /// The cutoff comes from the raw elements (not the clustered rows) so a lone
    /// narrative header survives `RowAssociator` merging.
    func test_calibrator_narrativeCutoffFromTransactionsHeader() {
        let totalsElements = [el("Total Credit", 20), el("220810", 120), el("Total Debit", 157), el("220810", 276)]
        let elements = [el("DETAILS OF TRANSACTIONS", 311, 200)] + totalsElements
        XCTAssertEqual(calibrator.calibrate(rows: [row(totalsElements)], elements: elements)?.narrativeCutoffX, 311)
    }

    func test_calibrator_nilWithoutTotalsRow() {
        let elements = [el("BPAY", 94), el("144700", 237)]
        XCTAssertNil(calibrator.calibrate(rows: [row(elements)], elements: elements))
    }

    // MARK: - Pairing

    func test_pairer_routesAmountsByNearestAnchor() {
        let bands = ColumnBands(creditAmountX: 237, debitAmountX: 452, narrativeCutoffX: .greatestFiniteMagnitude)
        let line = row([el("BPAY (12A)", 94), el("144700", 237), el("DSOP", 300), el("40000", 452)])
        let result = pairer.pair(rows: [line], bands: bands)
        XCTAssertEqual(result.earnings["BPAY (12A)"], 144700)
        XCTAssertEqual(result.deductions["DSOP"], 40000)
    }

    /// A code appearing in **both** columns stays unambiguous — each amount keeps its
    /// own-side label.
    func test_pairer_sameCodeInBothColumns() {
        let bands = ColumnBands(creditAmountX: 120, debitAmountX: 276, narrativeCutoffX: .greatestFiniteMagnitude)
        let line = row([el("ETKT", 20), el("484", 120), el("ETKT", 157), el("2129", 276)])
        let result = pairer.pair(rows: [line], bands: bands)
        XCTAssertEqual(result.earnings["ETKT"], 484)
        XCTAssertEqual(result.deductions["ETKT"], 2129)
    }

    /// Tokens at/after the narrative cutoff are dropped, not paired.
    func test_pairer_dropsNarrativeColumn() {
        let bands = ColumnBands(creditAmountX: 120, debitAmountX: 276, narrativeCutoffX: 311)
        let line = row([
            el("Basic Pay", 20), el("136400", 120),
            el("DSOPF Subn", 157), el("40000", 276), el("1436", 330)
        ])
        let result = pairer.pair(rows: [line], bands: bands)
        XCTAssertEqual(result.earnings["Basic Pay"], 136400)
        XCTAssertEqual(result.deductions["DSOPF Subn"], 40000)
        XCTAssertFalse(result.earnings.values.contains(1436))
        XCTAssertFalse(result.deductions.values.contains(1436))
    }

    func test_pairer_skipsStructuralRows() {
        let bands = ColumnBands(creditAmountX: 120, debitAmountX: 276, narrativeCutoffX: .greatestFiniteMagnitude)
        let totals = row([el("Total Credit", 20), el("220810", 120), el("Total Debit", 157), el("220810", 276)])
        let remit = row([el("REMITTANCE", 20), el("123052", 120)])
        let result = pairer.pair(rows: [totals, remit], bands: bands)
        XCTAssertTrue(result.earnings.isEmpty)
        XCTAssertTrue(result.deductions.isEmpty)
    }

    // MARK: - Totals semantics

    func test_semantics_newDirectTemplate() {
        let totals = OfficerColumnarTotals(gross: 275015, rightColumnTotal: 102029, remittance: nil)
        let resolved = semantics.resolve(totals)
        XCTAssertEqual(resolved?.template, .newDirect)
        XCTAssertEqual(resolved?.trueDeductions, 102029)
        XCTAssertEqual(resolved?.net, 172986)
    }

    func test_semantics_oldFoldedTemplate() {
        let totals = OfficerColumnarTotals(gross: 220810, rightColumnTotal: 220810, remittance: 123052)
        let resolved = semantics.resolve(totals)
        XCTAssertEqual(resolved?.template, .oldFolded)
        XCTAssertEqual(resolved?.trueDeductions, 97758)
        XCTAssertEqual(resolved?.net, 123052)
    }

    func test_semantics_oldFoldedNeedsRemittance() {
        let totals = OfficerColumnarTotals(gross: 220810, rightColumnTotal: 220810, remittance: nil)
        XCTAssertNil(semantics.resolve(totals))
    }

    // MARK: - Helpers

    private func el(_ text: String, _ x: CGFloat, _ y: CGFloat = 100) -> PositionalElement {
        PositionalElement(
            text: text,
            bounds: CGRect(x: x, y: y, width: 10, height: 10),
            type: CGPDFTokenExtractor.isAmount(text) ? .value : .label,
            confidence: 1.0,
            pageIndex: 1
        )
    }

    private func row(_ elements: [PositionalElement]) -> TableRow {
        TableRow(elements: elements, rowIndex: 0)
    }
}
