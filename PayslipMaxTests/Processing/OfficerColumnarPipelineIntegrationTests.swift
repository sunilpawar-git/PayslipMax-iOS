import CoreGraphics
@testable import PayslipMax
import XCTest

/// **Plan Phase 4 — DI + orchestration wiring.**
///
/// Drives the *fully DI-wired* `PDFProcessingService` (real `CGPDFTokenExtractor`,
/// calibrator, pairer, totals semantics, reconciliation gate and builder) over a
/// hand-authored, PII-free synthetic officer slip, proving:
///  - a reconciling `.defense` slip routes through `processPDFData` to the offline
///    columnar path and returns a `parsing.path == "columnar"` item — the hybrid
///    cascade (`HybridPayslipProcessor`) is never invoked,
///  - a non-reconciling slip is rejected by the gate so the service falls through
///    (`extractOfficerColumnar` returns `nil`) to the untouched pipeline.
///
/// No real slips, no `characterBounds`, no network.
@MainActor
final class OfficerColumnarPipelineIntegrationTests: XCTestCase {
    // Credit/debit X-bands from the plan's "2025 new" layout.
    private enum Band {
        static let creditLabel: CGFloat = 94
        static let creditAmount: CGFloat = 237
        static let debitLabel: CGFloat = 300
        static let debitAmount: CGFloat = 452
    }

    // MARK: - Accepted path (end-to-end through processPDFData)

    func test_reconcilingDefenseSlip_routesToColumnar_withoutHybridCascade() async throws {
        let service = try makeRealService()
        service.updateUserHint(.officer)

        let result = await service.processPDFData(SyntheticColumnarPDF.data([Self.reconcilingPage()]))

        guard case .success(let item) = result else {
            return XCTFail("expected the columnar path to succeed, got \(result)")
        }
        // Stamped by the columnar builder — proof the hybrid/LLM cascade never ran.
        XCTAssertEqual(item.metadata["parsing.path"], "columnar")
        XCTAssertEqual(item.metadata["parsing.template"], "newDirect")
        // Totals reconcile three ways.
        XCTAssertEqual(item.credits, 275015, accuracy: 1)
        XCTAssertEqual(item.debits, 102029, accuracy: 1)
        XCTAssertEqual(item.credits - item.debits, 172986, accuracy: 1)
        // Line items were paired by column, not vocabulary.
        XCTAssertEqual(item.earnings["BPAY"], 144700)
        XCTAssertEqual(item.deductions["DSOP"], 40000)
        XCTAssertEqual(item.earnings.values.reduce(0, +), item.credits, accuracy: 1)
        XCTAssertEqual(item.deductions.values.reduce(0, +), item.debits, accuracy: 1)
    }

    // MARK: - Fall-through path (gate rejection ⇒ nil ⇒ existing pipeline)

    func test_nonReconcilingSlip_isRejected_fallsThrough() async throws {
        let service = try makeRealService()

        // The columnar decision in isolation — a rejected parse must not yield an item,
        // so the `.defense` branch falls through to the untouched cascade.
        let item = await service.extractOfficerColumnar(
            data: SyntheticColumnarPDF.data([Self.nonReconcilingPage()]),
            firstPageText: ""
        )
        XCTAssertNil(item, "a non-reconciling slip must be rejected by the gate")
    }

    func test_reconcilingSlip_columnarDecision_returnsItem() async throws {
        let service = try makeRealService()

        let item = await service.extractOfficerColumnar(
            data: SyntheticColumnarPDF.data([Self.reconcilingPage()]),
            firstPageText: ""
        )
        XCTAssertEqual(item?.metadata["parsing.path"], "columnar")
    }

    // MARK: - Fixtures

    /// A single financial page whose line items + totals row reconcile exactly.
    /// Credits sum 275015, deductions sum 102029, net 172986 (newDirect template).
    private static func reconcilingPage() -> SyntheticColumnarPDF.Page {
        SyntheticColumnarPDF.page(
            creditPair("BPAY", "144700", y: 264) + debitPair("DSOP", "40000", y: 264)
            + creditPair("DA", "88110", y: 240) + debitPair("AGIF", "12500", y: 240)
            + creditPair("MSP", "15500", y: 216) + debitPair("ITAX", "47624", y: 216)
            + creditPair("RH12", "21125", y: 192) + debitPair("EHCESS", "1905", y: 192)
            + creditPair("TPTA", "3600", y: 168)
            + creditPair("TPTADA", "1980", y: 144)
            + totalsRow()
        )
    }

    /// Same totals, but a dropped earnings amount means Σ earnings ≠ gross — the gate rejects it.
    private static func nonReconcilingPage() -> SyntheticColumnarPDF.Page {
        SyntheticColumnarPDF.page(
            creditPair("BPAY", "144700", y: 264) + debitPair("DSOP", "40000", y: 264)
            + creditPair("DA", "88110", y: 240) + debitPair("AGIF", "12500", y: 240)
            + creditPair("MSP", "15500", y: 216) + debitPair("ITAX", "47624", y: 216)
            + debitPair("EHCESS", "1905", y: 192)
            + totalsRow()   // gross still claims 275015, but earnings only sum to 248110
        )
    }

    private static func totalsRow() -> [SyntheticColumnarPDF.Token] {
        [
            .init("Gross Pay", x: Band.creditLabel, y: 116),
            .init("275015", x: Band.creditAmount, y: 116),
            .init("Total Deductions", x: Band.debitLabel, y: 116),
            .init("102029", x: Band.debitAmount, y: 116)
        ]
    }

    private static func creditPair(_ label: String, _ amount: String, y: CGFloat) -> [SyntheticColumnarPDF.Token] {
        [.init(label, x: Band.creditLabel, y: y), .init(amount, x: Band.creditAmount, y: y)]
    }

    private static func debitPair(_ label: String, _ amount: String, y: CGFloat) -> [SyntheticColumnarPDF.Token] {
        [.init(label, x: Band.debitLabel, y: y), .init(amount, x: Band.debitAmount, y: y)]
    }

    /// The fully DI-wired service — real columnar extractor, gate and builder.
    private func makeRealService() throws -> PDFProcessingService {
        try XCTUnwrap(
            DIContainer.shared.makePDFProcessingService() as? PDFProcessingService,
            "expected the concrete PDFProcessingService from DI"
        )
    }
}
