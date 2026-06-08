import XCTest
@testable import PayslipMax

/// Phase A0 regression harness for the **new (Nov-2023+) bilingual PCDA(O)** officer
/// layout.
///
/// Reality discovered while building the harness: only the **totals** parse cleanly
/// offline today — the per-line-item extraction is broken for this layout too
/// (`BPAY (12A)` is read as `12`, and the arrears matcher emits spurious duplicate
/// components). So the harness splits the acceptance bar:
///
///  • `test_aug2025_totalsReconcile` — **green guard**; gross/deductions/net must
///    never regress.
///  • `test_aug2025_allLineItemsExtracted` — documented **red** (`XCTExpectFailure`);
///    the line-item extraction gap the Track-A fixes must close. Remove the wrapper
///    once line items reconcile.
final class OfficerParsingNewFormatTests: XCTestCase {
    func test_aug2025_totalsReconcile() async throws {
        let item = try await OfficerParsingHarness.parse(OfficerFixturesNewFormat.aug2025)
        OfficerParsingHarness.assertTotals(item, against: OfficerFixturesNewFormat.aug2025)
    }

    func test_aug2025_allLineItemsExtracted() async throws {
        let item = try? await OfficerParsingHarness.parse(OfficerFixturesNewFormat.aug2025)
        XCTExpectFailure("New-layout line-item extraction gap — closed by Track-A fixes") {
            guard let item else {
                XCTFail("2025-08: offline parse did not produce a payslip")
                return
            }
            OfficerParsingHarness.assertLineItems(item, against: OfficerFixturesNewFormat.aug2025)
        }
    }
}
