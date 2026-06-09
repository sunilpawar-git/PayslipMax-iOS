import XCTest
@testable import PayslipMax

/// Phase A0 regression harness for the **new (Nov-2023+) bilingual PCDA(O)** officer
/// layout.
///
/// The acceptance bar is split by extraction path:
///
///  • `test_aug2025_totalsReconcile` — **green guard**; the existing offline regex path
///    extracts totals cleanly, and gross/deductions/net must never regress.
///  • `test_aug2025_allLineItemsExtracted` — now **genuinely green** via the Phase 2
///    position-aware columnar extractor (the regex path's `BPAY (12A)` → `12` mangling
///    is bypassed); line items + totals reconcile exactly.
final class OfficerParsingNewFormatTests: XCTestCase {
    func test_aug2025_totalsReconcile() async throws {
        let item = try await OfficerParsingHarness.parse(OfficerFixturesNewFormat.aug2025)
        OfficerParsingHarness.assertTotals(item, against: OfficerFixturesNewFormat.aug2025)
    }

    @MainActor
    func test_aug2025_allLineItemsExtracted() async {
        let result = await OfficerParsingHarness.parseColumnar(OfficerPositionalFixturesNewFormat.aug2025)
        OfficerParsingHarness.assertColumnarFullyParsed(result, against: OfficerPositionalFixturesNewFormat.aug2025)
    }
}
