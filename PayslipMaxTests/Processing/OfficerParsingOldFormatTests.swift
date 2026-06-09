import XCTest
@testable import PayslipMax

/// Regression oracle for the **old (7th-CPC, 2016–Oct-2023) PCDA(O)** officer layout.
///
/// The old layout defeats the offline regex path on *both* axes — older component
/// spellings (`DSOPF Subn`, `Incm Tax`, `R/o Etkt`, …) and the folded `Total Debit`
/// that balances `Total Credit`. The Phase 2 position-aware columnar extractor closes
/// both: it pairs every line item by column geometry (vocabulary-free) and resolves the
/// `oldFolded` template (`true deductions = Total Credit − REMITTANCE`). These are now
/// **genuinely green** — no `XCTExpectFailure`.
final class OfficerParsingOldFormatTests: XCTestCase {
    @MainActor
    func test_aug2023_allLineItemsAndTotalsReconcile() async {
        let result = await OfficerParsingHarness.parseColumnar(OfficerPositionalFixturesOldFormat.aug2023)
        OfficerParsingHarness.assertColumnarFullyParsed(result, against: OfficerPositionalFixturesOldFormat.aug2023)
    }

    @MainActor
    func test_aug2022_allLineItemsAndTotalsReconcile() async {
        let result = await OfficerParsingHarness.parseColumnar(OfficerPositionalFixturesOldFormat.aug2022)
        OfficerParsingHarness.assertColumnarFullyParsed(result, against: OfficerPositionalFixturesOldFormat.aug2022)
    }
}
