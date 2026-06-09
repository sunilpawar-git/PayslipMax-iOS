@testable import PayslipMax
import XCTest

/// **Plan Phase 5 — corpus hardening.**
///
/// Drives the *whole* `OfficerPositionalCorpus` (2022–2025, both totals templates, old /
/// new / interleaved layouts, narrative-column and `ETKT`-both-columns cases) through the
/// real position-aware extractor, reconciliation gate and builder. The acceptance bar:
/// every fixture parses fully, reconciles three ways, passes the gate and builds a
/// reconciling `PayslipItem` — and a deliberately corrupted slip falls back cleanly.
///
/// Also pins the integration fixture's tol-15 row-spacing lesson as a corpus invariant.
@MainActor
final class OfficerPositionalCorpusTests: XCTestCase {
    private let gate = OfficerColumnarReconciliationGate()
    private let builder = OfficerColumnarPayslipBuilder()

    /// Every corpus fixture: full line-item extraction + three-way reconciliation, the gate
    /// accepts, and the built item's earnings/deductions/net reconcile.
    func test_corpus_everyFixtureFullyParsesReconcilesAndBuilds() async {
        for fixture in OfficerPositionalCorpus.all {
            let result = await OfficerParsingHarness.parseColumnar(fixture)
            OfficerParsingHarness.assertColumnarFullyParsed(result, against: fixture)
            guard let result else { continue }

            XCTAssertTrue(gate.accept(result), "\(fixture.label): gate rejected a reconciling result")
            let item = builder.build(result)
            XCTAssertEqual(item.credits - item.debits, fixture.expectedNetRemittance, accuracy: 1, fixture.label)
            XCTAssertEqual(item.earnings.values.reduce(0, +), item.credits, accuracy: 1, fixture.label)
            XCTAssertEqual(item.deductions.values.reduce(0, +), item.debits, accuracy: 1, fixture.label)
        }
    }

    /// Row-spacing invariant (the integration fixture's tol-15 lesson): every fixture's
    /// distinct rows clear `RowAssociator`'s tolerance, so clustering never merges two
    /// source rows into one and silently drops a line item.
    func test_corpus_rowSpacingExceedsAssociatorTolerance() {
        for fixture in OfficerPositionalCorpus.all {
            XCTAssertGreaterThan(
                fixture.minRowGap, ColumnLayout.rowTolerance,
                "\(fixture.label): rows spaced ≤ tol-15 will merge in RowAssociator"
            )
        }
    }

    /// The safety net: a corrupted slip (a dropped earnings line) extracts but fails the
    /// gate, so the `.defense` branch yields nothing and falls back to the existing cascade.
    func test_corpus_corruptedSlip_isRejectedByGate() async {
        let result = await OfficerParsingHarness.parseColumnar(OfficerPositionalCorpus.corruptedDroppedEarning)
        if let result {
            XCTAssertFalse(gate.accept(result), "a corrupted slip must not pass the reconciliation gate")
        }
    }
}
