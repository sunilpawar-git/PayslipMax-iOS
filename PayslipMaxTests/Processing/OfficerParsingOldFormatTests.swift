import XCTest
@testable import PayslipMax

/// Phase A0 regression oracle for the **old (7th-CPC, 2016–Oct-2023) PCDA(O)**
/// officer layout.
///
/// These are the documented baseline gap: the slips extract as clean text, but the
/// older component spellings are not yet in the catalogue, so the line items fail to
/// reconcile **today**. Each case is wrapped in `XCTExpectFailure` so the gap is
/// recorded as a *tracked, expected* red rather than breaking CI.
///
/// **Phase A1** (vocabulary expansion) must remove the `XCTExpectFailure` wrappers:
/// once the aliases land these flip to genuine green, and the strict expectation
/// will itself fail if a wrapper is left behind.
final class OfficerParsingOldFormatTests: XCTestCase {
    func test_aug2023_allLineItemsAndTotalsReconcile() async throws {
        let item = try? await OfficerParsingHarness.parse(OfficerFixturesOldFormat.aug2023)
        XCTExpectFailure("Old-format vocabulary gap — closed in Phase A1") {
            assertReconciles(item, against: OfficerFixturesOldFormat.aug2023)
        }
    }

    func test_aug2022_allLineItemsAndTotalsReconcile() async throws {
        let item = try? await OfficerParsingHarness.parse(OfficerFixturesOldFormat.aug2022)
        XCTExpectFailure("Old-format vocabulary gap — closed in Phase A1") {
            assertReconciles(item, against: OfficerFixturesOldFormat.aug2022)
        }
    }

    /// Synchronous bridge so the assertions live inside the `XCTExpectFailure`
    /// closure (which cannot be async). A nil item — i.e. the parse threw — is
    /// itself a documented failure of the old-format path.
    private func assertReconciles(
        _ item: PayslipItem?,
        against fixture: OfficerSlipFixture,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let item else {
            XCTFail("\(fixture.label): offline parse did not produce a payslip", file: file, line: line)
            return
        }
        OfficerParsingHarness.assertTotals(item, against: fixture, file: file, line: line)
        OfficerParsingHarness.assertLineItems(item, against: fixture, file: file, line: line)
    }
}
