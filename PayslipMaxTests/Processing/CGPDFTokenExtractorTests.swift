import CoreGraphics
@testable import PayslipMax
import XCTest

/// **Plan Phase 1 — real token extraction (CGPDFScanner), production port.**
///
/// Drives `CGPDFTokenExtractor` over hand-authored, PII-free synthetic PDFs whose geometry
/// mirrors the real officer columnar layout (label/amount X-bands from the plan's coordinate
/// table). Proves, with no real slips and no `characterBounds`:
///  - tokens reconstruct with the expected `(label, amount)` X-ordering,
///  - `RowAssociator` groups a `BPAY (12A)` label and its `144700` amount into one `TableRow`,
///  - Form-XObject pages extract via `Do` recursion (incl. a form `/Matrix` offset),
///  - a multi-page slip resolves to its financial page (not page 0),
///  - the amount classifier rejects `(12A)` so the old suffix-grabbing bug cannot recur.
final class CGPDFTokenExtractorTests: XCTestCase {
    private let extractor = CGPDFTokenExtractor()

    // Credit/debit X-bands from the plan's "2025 new (y=264)" row.
    private enum Band {
        static let creditLabel: CGFloat = 94
        static let creditAmount: CGFloat = 237
        static let debitLabel: CGFloat = 300
        static let debitAmount: CGFloat = 452
    }

    // MARK: - (label, amount) X-ordering

    func test_directPage_reconstructsLabelAmountXOrdering() throws {
        let page = try firstPage(of: [SyntheticColumnarPDF.page([
            .init("BPAY (12A)", x: Band.creditLabel, y: 264),
            .init("144700", x: Band.creditAmount, y: 264),
            .init("DSOP", x: Band.debitLabel, y: 264),
            .init("10000", x: Band.debitAmount, y: 264)
        ])])

        let elements = extractor.elements(on: page, pageIndex: 0)
        XCTAssertEqual(elements.map { $0.text }, ["BPAY (12A)", "144700", "DSOP", "10000"])

        let byText = Dictionary(uniqueKeysWithValues: elements.map { ($0.text, $0) })
        XCTAssertEqual(byText["BPAY (12A)"]?.bounds.minX ?? -1, Band.creditLabel, accuracy: 0.5)
        XCTAssertEqual(byText["144700"]?.bounds.minX ?? -1, Band.creditAmount, accuracy: 0.5)
        XCTAssertEqual(byText["10000"]?.bounds.minX ?? -1, Band.debitAmount, accuracy: 0.5)

        // Label vs amount classification is geometry-free and deterministic.
        XCTAssertEqual(byText["BPAY (12A)"]?.type, .label)
        XCTAssertEqual(byText["144700"]?.type, .value)
        XCTAssertEqual(byText["DSOP"]?.type, .label)
    }

    func test_amountClassifier_rejectsCodeSuffix() {
        XCTAssertTrue(CGPDFTokenExtractor.isAmount("144700"))
        XCTAssertTrue(CGPDFTokenExtractor.isAmount("1,44,700"))
        XCTAssertTrue(CGPDFTokenExtractor.isAmount("10000.00"))
        XCTAssertFalse(CGPDFTokenExtractor.isAmount("(12A)"))
        XCTAssertFalse(CGPDFTokenExtractor.isAmount("BPAY"))
        XCTAssertFalse(CGPDFTokenExtractor.isAmount("12A"))
    }

    // MARK: - RowAssociator pairing

    @MainActor
    func test_rowAssociator_groupsLabelAndAmountInSameRow() async throws {
        let page = try firstPage(of: [SyntheticColumnarPDF.page([
            .init("BPAY (12A)", x: Band.creditLabel, y: 264),
            .init("144700", x: Band.creditAmount, y: 264),
            .init("DSOP", x: Band.debitLabel, y: 264),
            .init("10000", x: Band.debitAmount, y: 264),
            .init("MSP", x: Band.creditLabel, y: 240),
            .init("15500", x: Band.creditAmount, y: 240),
            .init("AGIF", x: Band.debitLabel, y: 240),
            .init("5000", x: Band.debitAmount, y: 240)
        ])])
        let elements = extractor.elements(on: page, pageIndex: 0)

        let rows = try await RowAssociator().associateElementsIntoRows(elements, tolerance: 15)

        let bpayRow = try XCTUnwrap(rows.first { row in
            row.elements.contains { $0.text == "BPAY (12A)" }
        }, "no row contained the BPAY label")
        let texts = bpayRow.elements.map { $0.text }
        XCTAssertTrue(texts.contains("144700"), "BPAY label and its amount must share a row; got \(texts)")
        XCTAssertFalse(texts.contains("15500"), "the y=240 amount must not leak into the y=264 row")
    }

    // MARK: - Form XObject recursion

    func test_formXObjectPage_extractsViaDoRecursion() throws {
        let page = try firstPage(of: [SyntheticColumnarPDF.formPage([
            .init("BPAY", x: Band.creditLabel, y: 264),
            .init("144700", x: Band.creditAmount, y: 264)
        ])])
        let elements = extractor.elements(on: page, pageIndex: 0)

        XCTAssertEqual(Set(elements.map { $0.text }), ["BPAY", "144700"])
        let amount = try XCTUnwrap(elements.first { $0.text == "144700" })
        XCTAssertEqual(amount.bounds.minX, Band.creditAmount, accuracy: 0.5)
    }

    func test_formXObjectMatrix_offsetsTokenPositions() throws {
        // Form /Matrix translates the whole table up by 100 points; the extractor must apply it.
        let page = try firstPage(of: [SyntheticColumnarPDF.formPage(
            [.init("BPAY", x: Band.creditLabel, y: 264)],
            matrix: [1, 0, 0, 1, 0, 100]
        )])
        let elements = extractor.elements(on: page, pageIndex: 0)
        let bpay = try XCTUnwrap(elements.first { $0.text == "BPAY" })
        XCTAssertEqual(bpay.bounds.minX, Band.creditLabel, accuracy: 0.5)
        XCTAssertEqual(bpay.bounds.minY, 364, accuracy: 0.5)
    }

    // MARK: - Financial page detection

    func test_financialPageIndex_resolvesPastCoverPage() throws {
        let document = try XCTUnwrap(SyntheticColumnarPDF.document([
            SyntheticColumnarPDF.page([
                .init("PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS", x: 40, y: 700),
                .init("STATEMENT OF ACCOUNT", x: 40, y: 680)
            ]),
            SyntheticColumnarPDF.page([
                .init("BPAY (12A)", x: Band.creditLabel, y: 264),
                .init("144700", x: Band.creditAmount, y: 264),
                .init("DSOP", x: Band.debitLabel, y: 264),
                .init("10000", x: Band.debitAmount, y: 264)
            ]),
            SyntheticColumnarPDF.page([
                .init("Gross Pay", x: 40, y: 200),
                .init("275015", x: 242, y: 200),
                .init("Total Deductions", x: 300, y: 200),
                .init("102029", x: 448, y: 200)
            ])
        ]))

        XCTAssertEqual(extractor.financialPageIndex(in: document), 1)
    }

    func test_financialPageIndex_nilWhenNoFinancialPage() throws {
        let document = try XCTUnwrap(SyntheticColumnarPDF.document([
            SyntheticColumnarPDF.page([
                .init("STATEMENT OF ACCOUNT", x: 40, y: 700),
                .init("PAGE 1 OF 1", x: 40, y: 680)
            ])
        ]))
        XCTAssertNil(extractor.financialPageIndex(in: document))
    }

    // MARK: - Helpers

    private func firstPage(of pages: [SyntheticColumnarPDF.Page]) throws -> CGPDFPage {
        let document = try XCTUnwrap(SyntheticColumnarPDF.document(pages), "synthetic PDF failed to open")
        return try XCTUnwrap(document.page(at: 1), "synthetic PDF has no page 1")
    }
}
